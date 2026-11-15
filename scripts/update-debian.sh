#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Update Termux proot-distro to 5.8.0 or newer before running isolated Debian maintenance." >&2
  exit 2
fi

proot-distro login --isolated debian -- /bin/bash -lc '
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get full-upgrade -y
  apt-get autoremove -y
  apt-get autoclean
  apt-get clean
  apt-get check
'
echo "Debian packages updated. Run bash scripts/security-audit.sh to review the system."
