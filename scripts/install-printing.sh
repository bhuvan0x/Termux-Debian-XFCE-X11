#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

command -v proot-distro >/dev/null 2>&1 || {
  echo "Run scripts/setup-termux.sh first." >&2
  exit 1
}

proot-distro login debian -- /bin/bash -s <<'DEBIAN_PRINTING'
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

DEBIAN_ARCH="$(dpkg --print-architecture)"
if [ "$DEBIAN_ARCH" != "arm64" ]; then
  echo "This printer setup targets ARM64 Debian; detected: $DEBIAN_ARCH" >&2
  exit 2
fi

echo "== Installing CUPS, Epson ESC/P-R, Gutenprint and scanner tools =="
apt-get update
apt-get install -y \
  cups cups-client cups-filters cups-ipp-utils \
  printer-driver-escpr printer-driver-gutenprint \
  usbutils libsane1 sane-utils xdg-utils

if apt-cache show simple-scan >/dev/null 2>&1; then
  apt-get install -y simple-scan
else
  echo "simple-scan is not available in this Debian repository; scanner CLI remains available."
fi

if ! dpkg-query -W -f='${Status}' printer-driver-escpr 2>/dev/null | grep -qx 'install ok installed'; then
  echo "ERROR: printer-driver-escpr did not install successfully." >&2
  exit 1
fi

if ! id prime >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash prime
fi
getent group lpadmin >/dev/null 2>&1 && usermod -aG lpadmin prime || true
getent group lp >/dev/null 2>&1 && usermod -aG lp prime || true
getent group scanner >/dev/null 2>&1 && usermod -aG scanner prime || true

PRIME_HOME="$(getent passwd prime | cut -d: -f6)"
[ -n "$PRIME_HOME" ] && [ -d "$PRIME_HOME" ] || {
  echo "Could not resolve the prime desktop home directory." >&2
  exit 1
}
DESKTOP_DIR="$PRIME_HOME/Desktop"
APP_DIR="$PRIME_HOME/.local/share/applications"
install -d -m 0755 -o prime -g prime "$DESKTOP_DIR" "$APP_DIR"

# Replace the generic CUPS desktop shortcut with a model-specific Epson setup
# shortcut on both the XFCE desktop and the application menu.
write_epson_shortcut() {
  local destination="$1"
  cat > "$destination" <<'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Epson L3110 Series Setup
GenericName=Printer Setup
Comment=Configure the Epson L3110 Series printer in CUPS
Exec=firefox-esr --new-window http://127.0.0.1:631/admin
Icon=printer
Terminal=false
Categories=Settings;HardwareSettings;
StartupNotify=true
DESKTOP
  chown prime:prime "$destination"
  chmod 0644 "$destination"
}
write_epson_shortcut "$DESKTOP_DIR/epson-l3110-setup.desktop"
chmod 0755 "$DESKTOP_DIR/epson-l3110-setup.desktop"
write_epson_shortcut "$APP_DIR/epson-l3110-setup.desktop"

# Remove only the older generic shortcut created by this installer.
rm -f "$DESKTOP_DIR/printer-settings.desktop" "$APP_DIR/printer-settings.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi

if command -v simple-scan >/dev/null 2>&1; then
  cat > "$DESKTOP_DIR/simple-scan.desktop" <<'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Document Scanner
Comment=Scan using SANE-compatible scanners
Exec=simple-scan
Icon=org.gnome.SimpleScan
Terminal=false
Categories=Graphics;Scanning;
StartupNotify=true
DESKTOP
  chown prime:prime "$DESKTOP_DIR/simple-scan.desktop"
  chmod 0755 "$DESKTOP_DIR/simple-scan.desktop"
fi

apt-get clean
rm -rf /var/lib/apt/lists/*

DRIVER_VERSION="$(dpkg-query -W -f='${Version}' printer-driver-escpr)"
echo
echo "Printing stack installed for Debian ARM64."
echo "Epson ESC/P-R driver version: $DRIVER_VERSION"
echo "Epson L3110 Series Setup shortcut created on the XFCE desktop and in the Applications menu."
echo "After start-all, open that shortcut to reach CUPS Administration → Add Printer."
echo "Scanner support: SANE epson2 backend; check visibility with: scanimage -L"
echo "CUPS admin URL: http://127.0.0.1:631/admin"
echo "Set a password for the desktop user before CUPS administration:"
echo "  proot-distro login debian -- passwd prime"
DEBIAN_PRINTING

echo
echo "USB caveat: Android does not expose arbitrary USB devices as normal Linux device nodes to PRoot."
echo "The L3110 has USB connectivity only; network printing requires a separate USB print server/host."
