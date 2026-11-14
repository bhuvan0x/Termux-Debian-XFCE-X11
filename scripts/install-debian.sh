#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
command -v proot-distro >/dev/null || { echo "Run ./scripts/setup-termux.sh first." >&2; exit 1; }

if ! proot-distro list | grep -qE '^  debian([[:space:]]|$)'; then
  proot-distro install debian
fi

proot-distro login debian -- /bin/bash -lc '
  set -e
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get full-upgrade -y
  apt-get install -y \
    xfce4 xfce4-terminal thunar mousepad \
    dbus-x11 x11-xserver-utils \
    adwaita-icon-theme fonts-dejavu fonts-noto-core \
    ca-certificates curl wget git nano vim less sudo \
    dbus procps psmisc iproute2 net-tools \
    file unzip zip p7zip-full \
    build-essential pkg-config python3 python3-pip python3-venv \
    openssh-client rsync
  apt-get clean
  rm -rf /var/lib/apt/lists/*
'

echo "Debian + XFCE installation complete. Open Termux:X11, then run ./scripts/start-desktop.sh"
