#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Repair missing Debian XFCE components and desktop applications without
# touching the user's Xfconf, theme, wallpaper, panel or dock configuration.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

command -v proot-distro >/dev/null 2>&1 || {
  echo "proot-distro is missing. Run scripts/setup-termux.sh first." >&2
  exit 1
}

PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Update Termux proot-distro to 5.8.0 or newer first." >&2
  exit 2
fi

echo "Repairing Debian XFCE and reinstalling the desktop application bundle..."
echo "This does not run autoremove or reset desktop configuration."

bash "$SCRIPT_DIR/install-apps.sh"

# Restore Plank autostart for the existing prime desktop account.
# Keep its saved preferences and the existing XFCE top-panel configuration.
proot-distro login --isolated --user prime debian -- /bin/bash -s <<'DEBIAN_SCRIPT'
set -Eeuo pipefail
command -v plank >/dev/null 2>&1 || {
  echo "ERROR: Plank package is still unavailable after installation." >&2
  exit 3
}
install -d -m 0755 "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/plank.desktop" <<'PLANK_AUTOSTART'
[Desktop Entry]
Type=Application
Name=Plank Dock
Comment=Bottom application dock
Exec=plank
OnlyShowIn=XFCE;
StartupNotify=false
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
PLANK_AUTOSTART
chmod 0644 "$HOME/.config/autostart/plank.desktop"
DEBIAN_SCRIPT

echo
echo "Desktop repair completed."
echo "XFCE panel, terminal, file manager, Plank and the desktop application bundle have been installed."
echo "Your existing XFCE appearance and panel configuration were preserved."
echo "Now run: stop-all, then start-all"
