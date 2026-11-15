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
echo
echo "ClamAV command-line scanner installed."
echo "Updating virus signatures (initial download may be large)..."
if pgrep -x freshclam >/dev/null 2>&1; then
  echo "freshclam is already running; leaving the existing updater alone."
else
  freshclam --stdout --verbose
fi
echo
clamscan --version
echo "Use: bash scripts/scan-files.sh [absolute-Debian-path]"
echo "Default scan target: /home/prime/Downloads"
CLAMAV_INSTALL
