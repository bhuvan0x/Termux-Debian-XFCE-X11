#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
command -v proot-distro >/dev/null 2>&1 || { echo "proot-distro is missing." >&2; exit 1; }
[ -f "$SCRIPT_DIR/lowpaper-control-center.py" ] || { echo "Missing GUI source file." >&2; exit 1; }

proot-distro login --isolated --bind "$REPO_ROOT:/mnt/termux-debian-x11" debian -- /bin/bash -s <<'DEBIAN_INSTALL'
set -Eeuo pipefail
id prime >/dev/null 2>&1 || { echo "Debian user prime does not exist." >&2; exit 1; }
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-gi gir1.2-gtk-3.0
install -d -m 0755 -o prime -g prime /home/prime/.local/bin
install -d -m 0755 -o prime -g prime /home/prime/.local/share/applications
install -o prime -g prime -m 0755 /mnt/termux-debian-x11/scripts/lowpaper-control-center.py /home/prime/.local/bin/lowpaper-control-center
cat > /home/prime/.local/share/applications/lowpaper-control-center.desktop <<'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Lowpaper Control Center
GenericName=Live Wallpaper Manager
Comment=Manage MPV live wallpapers with lowpaper
Exec=/home/prime/.local/bin/lowpaper-control-center
Icon=preferences-desktop-wallpaper
Terminal=false
Categories=Settings;DesktopSettings;Utility;
StartupNotify=true
DESKTOP
chown prime:prime /home/prime/.local/share/applications/lowpaper-control-center.desktop
chmod 0644 /home/prime/.local/share/applications/lowpaper-control-center.desktop
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /home/prime/.local/share/applications >/dev/null 2>&1 || true
fi
echo "Lowpaper Control Center installed."
echo "Open XFCE Applications > Settings > Lowpaper Control Center"
echo "or run /home/prime/.local/bin/lowpaper-control-center"
DEBIAN_INSTALL
