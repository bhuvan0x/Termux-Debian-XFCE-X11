#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

if [ -z "${PREFIX:-}" ] || ! command -v proot-distro >/dev/null 2>&1; then
  echo "Run this script from Termux after installing proot-distro." >&2
  exit 1
fi

PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Security stop: proot-distro $PD_VERSION detected; version 5.8.0 or newer is required."
  echo "In Termux, run:"
  echo "  pkg update && pkg upgrade -y"
  echo "  pkg install proot-distro"
  echo "Then rerun this script. Do not use proot-distro copy/sync/restore with untrusted data."
  exit 2
fi

echo "== PrimeBook Debian hardening (PRoot-Distro $PD_VERSION) =="
proot-distro login --isolated debian -- /bin/bash -s <<'DEBIAN_HARDEN'
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

if [ "$(dpkg --print-architecture)" != "arm64" ]; then
  echo "Warning: expected ARM64 Debian; detected $(dpkg --print-architecture)."
fi

echo "== Refresh package metadata and install integrity checker =="
apt-get update
apt-get install -y debsums

echo "== Enforce signed APT repositories =="
cat > /etc/apt/apt.conf.d/99-primebook-security <<'APT_SECURITY'
APT::Get::AllowUnauthenticated "false";
Acquire::AllowInsecureRepositories "false";
Acquire::AllowDowngradeToInsecureRepositories "false";
Acquire::https::Verify-Peer "true";
Acquire::https::Verify-Host "true";
APT_SECURITY
chmod 0644 /etc/apt/apt.conf.d/99-primebook-security

echo "== Tighten password-authenticated sudo defaults =="
SUDO_TMP="$(mktemp /etc/sudoers.d/.primebook-security.XXXXXX)"
trap 'rm -f "$SUDO_TMP"' EXIT
cat > "$SUDO_TMP" <<'SUDO_SECURITY'
Defaults env_reset
Defaults timestamp_timeout=3
Defaults passwd_tries=3
Defaults logfile=/var/log/sudo.log
Defaults use_pty
SUDO_SECURITY
chmod 0440 "$SUDO_TMP"
chown root:root "$SUDO_TMP"
visudo -cf "$SUDO_TMP"
install -o root -g root -m 0440 "$SUDO_TMP" /etc/sudoers.d/99-primebook-security
rm -f "$SUDO_TMP"
trap - EXIT
visudo -c

echo "== Restrict CUPS to this device (if installed) =="
if [ -f /etc/cups/cupsd.conf ] && command -v cupsd >/dev/null 2>&1; then
  CUPS_CONF=/etc/cups/cupsd.conf
  CUPS_BACKUP=/etc/cups/cupsd.conf.primebook-pre-hardening
  [ -e "$CUPS_BACKUP" ] || cp -a "$CUPS_CONF" "$CUPS_BACKUP"
  python3 - "$CUPS_CONF" <<'PY'
import os, re, sys, tempfile
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    lines = f.readlines()
out = []
for line in lines:
    m = re.match(r"^\s*(Port|Listen)\s+(.+?)\s*(?:#.*)?$", line, re.I)
    if m:
        directive, value = m.group(1).lower(), m.group(2).strip()
        if directive == "port":
            continue
        if value.startswith("/"):
            out.append(line)  # Preserve the local Unix-domain socket.
            continue
        if value.lower().startswith(("localhost:", "127.0.0.1:", "[::1]:")):
            out.append(line)
            continue
        continue  # Remove wildcard and non-loopback TCP listeners.
    if re.match(r"^\s*(Browsing|DefaultShared)\s+", line, re.I):
        continue
    out.append(line)
if not any(re.match(r"^\s*Listen\s+(localhost:|127\.0\.0\.1:|\[::1\]:)", x, re.I) for x in out):
    out.append("\nListen 127.0.0.1:631\n")
out.extend(["\nBrowsing Off\n", "DefaultShared No\n"])
fd, tmp = tempfile.mkstemp(prefix=".cupsd.conf.", dir=os.path.dirname(path))
try:
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.writelines(out)
    os.chmod(tmp, os.stat(path).st_mode & 0o777)
    os.chown(tmp, os.stat(path).st_uid, os.stat(path).st_gid)
    os.replace(tmp, path)
finally:
    if os.path.exists(tmp):
        os.unlink(tmp)
PY
  if cupsd -t; then
    echo "CUPS configuration is valid and limited to loopback."
  else
    echo "WARNING: CUPS configuration validation failed; restoring backup."
    cp -a "$CUPS_BACKUP" "$CUPS_CONF"
    cupsd -t || true
  fi
else
  echo "CUPS not installed; skipping."
fi

echo
echo "Hardening settings applied. No network daemons were enabled."
echo "Automatic background security updates are not enabled: this PRoot setup has no systemd service manager."
echo "Use: bash scripts/update-debian.sh regularly, then: bash scripts/security-audit.sh"
DEBIAN_HARDEN

echo
echo "Debian hardening complete. Run: bash scripts/security-audit.sh"
