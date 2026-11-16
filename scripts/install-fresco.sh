#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Run from Termux. Fresco itself is built inside the isolated Debian PRoot.
if ! command -v proot-distro >/dev/null 2>&1; then
  echo "proot-distro is missing. Run scripts/setup-termux.sh first." >&2
  exit 1
fi

BUILD_DIR="${1:-/home/prime/src/Fresco/target/release}"
proot-distro login --isolated debian -- /usr/bin/env "FRESCO_BUILD_DIR=$BUILD_DIR" /bin/bash -s <<'DEBIAN_SCRIPT'
set -Eeuo pipefail

if [ "$(dpkg --print-architecture)" != "arm64" ]; then
  echo "Fresco installer currently targets Debian ARM64." >&2
  exit 2
fi

if ! id prime >/dev/null 2>&1; then
  echo "The Debian desktop user 'prime' does not exist. Run install-debian.sh first." >&2
  exit 1
fi

PRIME_HOME="$(getent passwd prime | cut -d: -f6)"
SOURCE_DIR="${FRESCO_BUILD_DIR:-$PRIME_HOME/src/Fresco/target/release}"
FRESCO_SOURCE="$SOURCE_DIR/fresco"
DAEMON_SOURCE="$SOURCE_DIR/frescod"

for binary in "$FRESCO_SOURCE" "$DAEMON_SOURCE"; do
  if [ ! -x "$binary" ]; then
    echo "Missing executable: $binary" >&2
    echo "Build Fresco v1.1.55 first, or pass its target/release directory as the script argument." >&2
    exit 1
  fi
  if ! readelf -h "$binary" 2>/dev/null | grep -q 'AArch64'; then
    echo "Not an AArch64 executable: $binary" >&2
    exit 1
  fi
  missing="$(ldd "$binary" 2>&1 | grep 'not found' || true)"
  if [ -n "$missing" ]; then
    echo "Unresolved shared libraries for $binary:" >&2
    printf '%s\n' "$missing" >&2
    exit 1
  fi
done

if ! dpkg-query -W -f='${Status}' libmpv2 2>/dev/null | grep -q 'install ok installed'; then
  echo "libmpv2 is required by Fresco. Install it with: apt-get install libmpv2" >&2
  exit 1
fi

echo "Installing Fresco and Fresco daemon..."
install -d -m 0755 /usr/local/bin
install -o root -g root -m 0755 "$FRESCO_SOURCE" /usr/local/bin/fresco
install -o root -g root -m 0755 "$DAEMON_SOURCE" /usr/local/bin/frescod

APP_DIR="$PRIME_HOME/.local/share/applications"
install -d -m 0755 -o prime -g prime "$APP_DIR"
cat > "$APP_DIR/fresco.desktop" <<'FRESCO_DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Fresco
GenericName=Live Wallpaper Manager
Comment=Manage and display live wallpapers
TryExec=/usr/local/bin/fresco
Exec=/usr/local/bin/fresco
Icon=video-display
Terminal=false
Categories=Settings;DesktopSettings;
Keywords=wallpaper;live;video;desktop;
StartupNotify=false
Actions=Next;Previous;Random;Picker;

[Desktop Action Next]
Name=Next Wallpaper
Exec=/usr/local/bin/fresco next

[Desktop Action Previous]
Name=Previous Wallpaper
Exec=/usr/local/bin/fresco prev

[Desktop Action Random]
Name=Random Wallpaper
Exec=/usr/local/bin/fresco random

[Desktop Action Picker]
Name=Choose Wallpaper
Exec=/usr/local/bin/fresco pick
FRESCO_DESKTOP
chown prime:prime "$APP_DIR/fresco.desktop"
chmod 0644 "$APP_DIR/fresco.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
  runuser -u prime -- env HOME="$PRIME_HOME" \
    XDG_DATA_HOME="$PRIME_HOME/.local/share" \
    update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi

echo
echo "Fresco installed:"
echo "  /usr/local/bin/fresco"
echo "  /usr/local/bin/frescod"
echo "  $APP_DIR/fresco.desktop"
echo
echo "Open Applications > Settings > Fresco, or search for Fresco in XFCE App Finder."
echo "This installer does not enable autostart or change your current wallpaper."
DEBIAN_SCRIPT
