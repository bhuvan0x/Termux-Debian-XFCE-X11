#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

command -v proot-distro >/dev/null 2>&1 || {
  echo "proot-distro is missing. Run scripts/setup-termux.sh first." >&2
  exit 1
}
PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Update Termux proot-distro to version 5.8.0 or newer first." >&2
  exit 2
fi

echo "== Installing GNOME Software Center for Debian ARM64 =="

proot-distro login --isolated debian -- /bin/bash -s <<'DEBIAN_SCRIPT'
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

ARCH="$(dpkg --print-architecture)"
if [ "$ARCH" != "arm64" ]; then
  echo "This installer targets Debian ARM64; detected: $ARCH" >&2
  exit 3
fi

apt-get update
apt-get install -y \
  gnome-software \
  gnome-software-plugin-deb \
  gnome-software-plugin-flatpak \
  flatpak \
  packagekit \
  appstream \
  apt-config-icons \
  xdg-desktop-portal \
  xdg-desktop-portal-gtk

PRIME_HOME="$(getent passwd prime | cut -d: -f6)"
[ -n "$PRIME_HOME" ] && [ -d "$PRIME_HOME" ] || {
  echo "The prime desktop user does not exist. Run scripts/install-apps.sh first." >&2
  exit 4
}

# Add Flathub only to prime's per-user Flatpak configuration. This avoids
# changing the system installation or requiring root just to register a source.
install -d -m 0755 -o prime -g prime "$PRIME_HOME/.local/share"
runuser -u prime -- env HOME="$PRIME_HOME" \
  flatpak remote-add --user --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo

APP_DIR="$PRIME_HOME/.local/share/applications"
DESKTOP_DIR="$PRIME_HOME/Desktop"
install -d -m 0755 -o prime -g prime "$APP_DIR" "$DESKTOP_DIR"

cat > "$APP_DIR/primebook-software-center.desktop" <<'SOFTWARE_MENU'
[Desktop Entry]
Version=1.0
Type=Application
Name=Software Center
GenericName=Application Store
Comment=Browse Debian and Flathub applications and updates
Exec=gnome-software --mode=overview
Icon=org.gnome.Software
Terminal=false
Categories=System;PackageManager;
StartupNotify=true
SOFTWARE_MENU

install -m 0644 "$APP_DIR/primebook-software-center.desktop" "$DESKTOP_DIR/Software Center.desktop"
chown prime:prime "$APP_DIR/primebook-software-center.desktop" "$DESKTOP_DIR/Software Center.desktop"

if command -v appstreamcli >/dev/null 2>&1; then
  appstreamcli refresh-cache --force >/dev/null 2>&1 || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi

echo
echo "GNOME Software: $(dpkg-query -W -f='${Version}' gnome-software)"
echo "Debian APT plugin: installed"
echo "Flatpak plugin: installed"
echo "Flathub remote: configured for user prime"
echo "Launcher: $DESKTOP_DIR/Software Center.desktop"
echo
echo "PRoot note: GNOME Software's catalogue can be browsed, but PackageKit/Polkit"
echo "install and update actions depend on system-D-Bus service support. Flatpak"
echo "deployments also depend on Android kernel sandbox features. If an action is"
echo "blocked, use the existing Debian APT workflow rather than weakening isolation."
DEBIAN_SCRIPT

echo
echo "GNOME Software has been installed. It will appear in XFCE's Applications menu"
echo "as Software Center after the desktop is restarted."
