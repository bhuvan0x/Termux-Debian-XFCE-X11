#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

if ! command -v proot-distro >/dev/null 2>&1; then
  echo "proot-distro is missing. Run scripts/setup-termux.sh first." >&2
  exit 1
fi

# Install the official ARM64 Debian package and create a PRoot-compatible
# per-user XFCE launcher. Run from Termux, not from inside the Debian shell.
proot-distro login --isolated debian -- /bin/bash -s <<'DEBIAN_SCRIPT'
set -Eeuo pipefail

ARCH="$(dpkg --print-architecture)"
if [ "$ARCH" != "arm64" ]; then
  echo "This installer targets Debian arm64; detected: $ARCH" >&2
  exit 1
fi

if ! id prime >/dev/null 2>&1; then
  echo "The Debian desktop user 'prime' does not exist. Run install-debian.sh first." >&2
  exit 1
fi

command -v wget >/dev/null 2>&1 || {
  echo "wget is missing. Install it with: apt-get update && apt-get install -y wget" >&2
  exit 1
}

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
DEB_FILE="$TEMP_DIR/code_arm64.deb"

echo "Downloading the official stable VS Code Debian ARM64 package..."
wget -O "$DEB_FILE"   "https://update.code.visualstudio.com/latest/linux-deb-arm64/stable"

DEB_ARCH="$(dpkg-deb -f "$DEB_FILE" Architecture)"
if [ "$DEB_ARCH" != "arm64" ]; then
  echo "Downloaded package architecture is '$DEB_ARCH', expected 'arm64'." >&2
  exit 1
fi

echo "Installing Visual Studio Code ($DEB_ARCH)..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y "$DEB_FILE"

if [ ! -x /usr/share/code/code ]; then
  echo "VS Code installed, but /usr/share/code/code was not found." >&2
  exit 1
fi

PRIME_HOME="$(getent passwd prime | cut -d: -f6)"
APP_DIR="$PRIME_HOME/.local/share/applications"
install -d -m 0755 -o prime -g prime "$APP_DIR"

# Override only prime's desktop launchers. The system-wide package files stay
# untouched and package upgrades will not erase this per-user compatibility fix.
for filename in com.microsoft.VSCode.desktop com.microsoft.VSCode.UrlHandler.desktop; do
  source="/usr/share/applications/$filename"
  [ -f "$source" ] || continue
  target="$APP_DIR/$filename"
  sed -E '/^Exec=\/usr\/share\/code\/code([[:space:]]|$)/ { /--no-sandbox/! s|^Exec=/usr/share/code/code|Exec=/usr/share/code/code --no-sandbox --disable-gpu|; }'     "$source" > "$TEMP_DIR/$filename"
  install -o prime -g prime -m 0644 "$TEMP_DIR/$filename" "$target"
done

echo
echo "VS Code installation and XFCE launcher configuration complete."
echo "Open Applications > Development > Visual Studio Code."
echo "PRoot compatibility options: --no-sandbox --disable-gpu"
DEBIAN_SCRIPT
