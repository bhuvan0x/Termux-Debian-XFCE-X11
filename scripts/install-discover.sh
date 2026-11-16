#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
command -v proot-distro >/dev/null 2>&1 || { echo "proot-distro is missing. Run scripts/setup-termux.sh first." >&2; exit 1; }
PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Update Termux proot-distro to version 5.8.0 or newer first." >&2
  exit 2
fi
echo "== Installing KDE Discover for Debian ARM64 =="
proot-distro login --isolated debian -- /bin/bash -s <<'DEBIAN_SCRIPT'
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
ARCH="$(dpkg --print-architecture)"
if [ "$ARCH" != "arm64" ]; then echo "This installer targets Debian ARM64; detected: $ARCH" >&2; exit 3; fi
apt-get update
apt-get install -y plasma-discover plasma-discover-backend-flatpak flatpak packagekit appstream apt-config-icons dbus dbus-x11
PRIME_HOME="$(getent passwd prime | cut -d: -f6)"
[ -n "$PRIME_HOME" ] && [ -d "$PRIME_HOME" ] || { echo "The prime desktop user does not exist. Run scripts/install-apps.sh first." >&2; exit 4; }

# Keep Flathub per-user; no system-wide Flatpak changes are made.
install -d -m 0755 -o prime -g prime "$PRIME_HOME/.local/share"
if runuser -u prime -- env HOME="$PRIME_HOME" flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
  echo "Flathub user remote is configured."
else
  echo "WARNING: Flathub could not be configured. Discover and APT support remain installed."
fi

# Install Discover before removing the previous GNOME storefront. Shared
# PackageKit and Flatpak dependencies are intentionally retained.
if dpkg-query -W -f='${Status}' gnome-software 2>/dev/null | grep -q 'install ok installed'; then
  apt-get purge -y gnome-software gnome-software-plugin-deb gnome-software-plugin-flatpak || true
fi

APP_DIR="$PRIME_HOME/.local/share/applications"
DESKTOP_DIR="$PRIME_HOME/Desktop"
install -d -m 0755 -o prime -g prime "$APP_DIR" "$DESKTOP_DIR"

cat > /usr/local/bin/primebook-discover <<'DISCOVER_WRAPPER'
#!/bin/bash
set -u
LOG_DIR="$HOME/Documents"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/discover.log"
{
  printf '\n===== Discover launch: %s =====\n' "$(date -Is)"
  printf 'User: %s | DISPLAY: %s\n' "$(id -un)" "${DISPLAY:-unset}"
  if ! dbus-send --system --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListNames >/dev/null 2>&1; then
    echo "ERROR: The Debian system D-Bus is unavailable."
    echo "Stop the desktop and start it again with start-all; the updated startup script initializes the system bus."
    exit 1
  fi
  echo "System D-Bus: reachable"
} >> "$LOG_FILE" 2>&1
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-xcb}"
exec /usr/bin/plasma-discover "$@" >> "$LOG_FILE" 2>&1
DISCOVER_WRAPPER
chmod 0755 /usr/local/bin/primebook-discover
chown root:root /usr/local/bin/primebook-discover

cat > "$APP_DIR/primebook-discover.desktop" <<'DISCOVER_MENU'
[Desktop Entry]
Version=1.0
Type=Application
Name=Discover
GenericName=Software Center
Comment=Browse and manage Debian and Flatpak applications
Exec=/usr/local/bin/primebook-discover %U
Icon=plasmadiscover
Terminal=false
Categories=System;PackageManager;
StartupNotify=true
DISCOVER_MENU
install -m 0644 "$APP_DIR/primebook-discover.desktop" "$DESKTOP_DIR/Discover.desktop"
chown prime:prime "$APP_DIR/primebook-discover.desktop" "$DESKTOP_DIR/Discover.desktop"
rm -f "$APP_DIR/primebook-software-center.desktop" "$DESKTOP_DIR/Software Center.desktop"
if command -v update-desktop-database >/dev/null 2>&1; then update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true; fi

echo
echo "KDE Discover: $(dpkg-query -W -f='${Version}' plasma-discover)"
echo "Flatpak backend: $(dpkg-query -W -f='${Version}' plasma-discover-backend-flatpak)"
echo "PackageKit: $(dpkg-query -W -f='${Version}' packagekit)"
echo "Flathub: per-user remote for prime (if network setup succeeded)"
echo "Launcher: $APP_DIR/primebook-discover.desktop"
echo
echo "The desktop startup script starts a temporary system D-Bus for the lifetime"
echo "of XFCE. PackageKit authorization and Flatpak sandbox operations remain"
echo "subject to PRoot/Android limitations; use APT in a root Debian session for"
echo "reliable package installation and system updates."
DEBIAN_SCRIPT
echo
echo "Discover is installed. Restart XFCE with start-all to activate the system D-Bus."
