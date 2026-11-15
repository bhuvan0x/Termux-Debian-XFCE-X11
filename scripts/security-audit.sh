#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

if [ -z "${PREFIX:-}" ] || ! command -v proot-distro >/dev/null 2>&1; then
  echo "Run this audit from Termux." >&2
  exit 1
fi
RUN_INTEGRITY=0
case "${1:-}" in
  "") ;;
  --integrity) RUN_INTEGRITY=1 ;;
  *) echo "Usage: bash scripts/security-audit.sh [--integrity]" >&2; exit 2 ;;
esac
PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
printf 'Termux proot-distro: %s\n' "${PD_VERSION:-missing}"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "WARNING: update Termux packages; isolated login requires proot-distro >= 5.8.0."
  exit 2
fi

echo
echo "===== TERMUX HOST APP SANDBOX ====="
printf 'Termux HOME: %s\n' "$HOME"
stat -c 'HOME mode: %a  owner: %U  group: %G' "$HOME" 2>/dev/null || ls -ld "$HOME"
if [ "$(stat -c '%a' "$HOME" 2>/dev/null || echo 700)" != "700" ]; then
  echo "NOTICE: Termux HOME is not mode 700. Review before changing it."
fi
echo
echo "Installed security-relevant Termux packages:"
pkg list-installed 2>/dev/null | grep -E '^(proot|proot-distro|openssl|openssh|termux-api|termux-tools)/' || true
echo
echo "Upgradable Termux packages:"
apt list --upgradable 2>/dev/null | sed -n '1,50p' || true

echo
echo "===== TERMUX HOST LISTENERS ====="
if command -v sshd >/dev/null 2>&1; then
  if pgrep -af '[s]shd' >/dev/null 2>&1; then
    echo "NOTICE: Termux sshd process detected:"
    pgrep -af '[s]shd' || true
  else
    echo "Termux OpenSSH is installed, but no sshd process was detected."
  fi
else
  echo "Termux OpenSSH server binary is not installed."
fi
if command -v ss >/dev/null 2>&1; then
  SS_OUTPUT="$(ss -lntup 2>&1 || true)"
  printf '%s\n' "$SS_OUTPUT"
  if printf '%s\n' "$SS_OUTPUT" | grep -q "Cannot open netlink socket: Permission denied"; then
    echo "LIMITATION: Android denied netlink socket inspection; host listener inventory is incomplete."
  fi
else
  echo "ss is not installed in Termux; rerun setup-termux.sh to install iproute2."
fi

echo
echo "===== DEBIAN SECURITY AUDIT ====="
proot-distro login --isolated debian -- /usr/bin/env "RUN_INTEGRITY=$RUN_INTEGRITY" /bin/bash -s <<'DEBIAN_AUDIT'
set -u
section() { printf '\n===== %s =====\n' "$1"; }
section "OS AND KERNEL BOUNDARY"
cat /etc/os-release 2>/dev/null | grep -E '^(PRETTY_NAME|VERSION_ID)=' || true
printf 'Architecture: '; dpkg --print-architecture
printf 'Kernel exposed by Android host: '; uname -r
echo "Note: this is Debian userspace under PRoot; Android supplies the kernel."

section "PACKAGE UPDATE STATUS"
apt list --upgradable 2>/dev/null | sed -n '1,80p' || true
apt-get check 2>&1 || true

section "APT SIGNATURE POLICY"
cat /etc/apt/apt.conf.d/99-primebook-security 2>/dev/null || echo "Hardening config missing: run scripts/harden-debian.sh."

section "SUDO AND ACCOUNT"
visudo -c 2>&1 || echo "WARNING: visudo validation reported a problem."
if [ -d /etc/sudoers.d ]; then
  BAD_SUDOERS="$(find /etc/sudoers.d -maxdepth 1 -type f \( ! -perm 0440 -o ! -user root -o ! -group root \) -print 2>/dev/null || true)"
  if [ -n "$BAD_SUDOERS" ]; then
    echo "WARNING: sudoers drop-ins with unsafe owner/mode:"
    printf '%s\n' "$BAD_SUDOERS"
  else
    echo "PASS: sudoers drop-in files have root ownership and mode 0440."
  fi
fi
passwd -S prime 2>&1 || true
if grep -RnsE 'NOPASSWD|!authenticate' /etc/sudoers /etc/sudoers.d 2>/dev/null; then
  echo "WARNING: review the sudo exceptions above."
else
  echo "No NOPASSWD or !authenticate rule found."
fi
grep -RnsE 'timestamp_timeout|passwd_tries|use_pty|logfile' /etc/sudoers /etc/sudoers.d 2>/dev/null || true

section "LISTENING NETWORK SERVICES"
if command -v ss >/dev/null 2>&1; then
  ss -lntup 2>&1 || true
else
  echo "ss unavailable; install iproute2."
fi
if dpkg-query -W -f='${Status}' openssh-server 2>/dev/null | grep -q 'install ok installed'; then
  echo "NOTICE: openssh-server is installed. Confirm you intentionally need it and that it is not exposed beyond loopback."
else
  echo "OpenSSH server package is not installed."
fi

section "CUPS NETWORK BINDING"
if [ -f /etc/cups/cupsd.conf ]; then
  grep -nE '^[[:space:]]*(Listen|Port|Browsing|DefaultShared)[[:space:]]' /etc/cups/cupsd.conf || true
  if grep -E '^[[:space:]]*(Port[[:space:]]+|Listen[[:space:]]+\*:|Listen[[:space:]]+0\.0\.0\.0:|Listen[[:space:]]+\[::\]:)' /etc/cups/cupsd.conf >/dev/null; then
    echo "WARNING: CUPS may be listening beyond loopback. Run scripts/harden-debian.sh."
  else
    echo "PASS: no wildcard CUPS TCP listener found in cupsd.conf."
  fi
  if grep -E '^[[:space:]]*Browsing[[:space:]]+Yes([[:space:]]|$)' /etc/cups/cupsd.conf >/dev/null; then
    echo "WARNING: CUPS browsing is enabled; run scripts/harden-debian.sh."
  else
    echo "PASS: CUPS browsing is disabled."
  fi
  if grep -E '^[[:space:]]*DefaultShared[[:space:]]+Yes([[:space:]]|$)' /etc/cups/cupsd.conf >/dev/null; then
    echo "WARNING: CUPS printer sharing is enabled; run scripts/harden-debian.sh."
  else
    echo "PASS: CUPS printer sharing is disabled."
  fi
  cupsd -t 2>&1 || true
else
  echo "CUPS is not installed."
fi
section "CLAMAV SCANNER"
if command -v clamscan >/dev/null 2>&1; then
  clamscan --version
  if compgen -G '/var/lib/clamav/*.cvd' >/dev/null || compgen -G '/var/lib/clamav/*.cld' >/dev/null; then
    stat -c '%y %n' /var/lib/clamav/*.cvd /var/lib/clamav/*.cld 2>/dev/null || true
  else
    echo "ClamAV signatures are missing; run freshclam in an isolated Debian root session."
  fi
else
  echo "Optional ClamAV scanner is not installed."
fi

section "PACKAGE FILE INTEGRITY"
if command -v debsums >/dev/null 2>&1; then
  if [ "${RUN_INTEGRITY:-0}" = "1" ]; then
    echo "Running full package-file integrity scan; this can take several minutes."
    echo "Any reported paths indicate mismatches or missing package files:"
    debsums -s 2>&1 | sed -n '1,100p' || true
    echo "Package-file integrity scan finished."
  else
    echo "debsums is installed. Full scan skipped in quick audit mode."
    echo "Run: bash scripts/security-audit.sh --integrity"
  fi
else
  echo "debsums is not installed; run scripts/harden-debian.sh."
fi
section "SSH KEY FILE PERMISSIONS"
if [ -d /home/prime/.ssh ]; then
  stat -c '%a %U:%G %n' /home/prime/.ssh /home/prime/.ssh/* 2>/dev/null || true
else
  echo "No /home/prime/.ssh directory."
fi

section "SECURITY SOFTWARE LIMITATIONS"
echo "AppArmor, kernel firewall rules, kernel sysctls, systemd timers and auditd cannot be relied on inside this PRoot guest."
echo "Do not count UFW/Fail2ban as a host firewall for this setup."
DEBIAN_AUDIT

echo
echo "Audit finished. Review every WARNING/NOTICE; this tool does not certify the device as secure."
