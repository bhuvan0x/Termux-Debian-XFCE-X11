#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

if [ -z "${PREFIX:-}" ] || ! command -v proot-distro >/dev/null 2>&1; then
  echo "Run this script from Termux." >&2
  exit 1
fi
PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Update proot-distro to 5.8.0 or newer before installing ClamAV." >&2
  exit 2
fi

proot-distro login --isolated debian -- /bin/bash -s <<'CLAMAV_INSTALL'
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
if [ "$(dpkg --print-architecture)" != "arm64" ]; then
  echo "This installer targets ARM64 Debian; found $(dpkg --print-architecture)." >&2
  exit 2
fi
apt-get update
apt-get install -y clamav clamav-freshclam
install -d -m 0755 -o clamav -g clamav /var/lib/clamav
# Keep the scanner on demand in PRoot: do not leave a background updater
# running in a guest that has no reliable service manager.
if command -v update-rc.d >/dev/null 2>&1; then
  update-rc.d clamav-freshclam disable >/dev/null 2>&1 || true
fi
if command -v systemctl >/dev/null 2>&1; then
  systemctl disable --now clamav-freshclam.service >/dev/null 2>&1 || true
fi
pkill -TERM -x freshclam >/dev/null 2>&1 || true
sleep 1
echo
echo "ClamAV command-line scanner installed; automatic updater service disabled."
echo "Updating virus signatures (initial download may be large)..."
freshclam --stdout --verbose
echo
clamscan --version
echo "Use: bash scripts/scan-files.sh [absolute-Debian-path]"
echo "Default scan target: /home/prime/Downloads"
CLAMAV_INSTALL
