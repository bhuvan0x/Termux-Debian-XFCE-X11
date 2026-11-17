#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
command -v proot-distro >/dev/null 2>&1 || { echo "proot-distro is required." >&2; exit 1; }
echo "== Installing Wallpaper Control Centre dependencies =="
proot-distro login --isolated debian -- /bin/bash -lc '
  set -Eeuo pipefail
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y python3 python3-gi gir1.2-gtk-3.0 xfconf mpv python3-xlib libxfixes3 build-essential pkg-config libx11-dev libxext-dev libxrender-dev
'
echo "== Installing Wallpaper Control Centre for prime =="
proot-distro login --isolated --user prime debian -- /bin/bash -lc '
  set -Eeuo pipefail
  SRC=/home/prime/.local/src/WALLPAPER-CONTROL-CENTRE
  mkdir -p /home/prime/.local/src
  if [ -d "$SRC/.git" ]; then
    git -C "$SRC" pull --ff-only
  else
    git clone --depth 1 https://github.com/bhuvan0x/WALLPAPER-CONTROL-CENTRE.git "$SRC"
  fi
  bash "$SRC/install.sh"
'
echo "Wallpaper Control Centre is installed for the prime desktop user."
