#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

if [ -z "${PREFIX:-}" ] || ! command -v proot-distro >/dev/null 2>&1; then
  echo "Run this script from Termux." >&2
  exit 1
fi
PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Update proot-distro to 5.8.0 or newer before updating ClamAV." >&2
  exit 2
fi

proot-distro login --isolated debian -- /bin/bash -lc '
  if ! command -v freshclam >/dev/null 2>&1; then
    echo "ClamAV signature updater is not installed. Run scripts/install-clamav.sh." >&2
    exit 127
  fi
  if pgrep -x freshclam >/dev/null 2>&1; then
    echo "freshclam is already running; stop the updater before running a manual update." >&2
    exit 1
  fi
  freshclam --stdout --verbose
'
