#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

command -v proot-distro >/dev/null 2>&1 || {
  echo "Run scripts/setup-termux.sh first." >&2
  exit 1
}

proot-distro login --isolated debian -- /bin/bash -s <<'DEBIAN_PRINTING'
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

DEBIAN_ARCH="$(dpkg --print-architecture)"
if [ "$DEBIAN_ARCH" != "arm64" ]; then
  echo "This printer setup targets ARM64 Debian; detected: $DEBIAN_ARCH" >&2
  exit 2
fi

echo "== Installing CUPS, Gutenprint and scanner tools =="
apt-get update
apt-get install -y \
  cups cups-client cups-filters cups-ipp-utils \
  printer-driver-gutenprint usbutils libsane1 sane-utils xdg-utils

# Debian 13/Trixie's 1.7.17 ESC/P-R package does not ship an L3110 PPD.
# Debian's newer 1.8.8 ARM64 build does. Temporarily add Forky, pin only
# printer-driver-escpr from that suite, then remove the temporary source.
ESC_PRR_MIN_VERSION="1.8.8-1"
installed_driver_version="$(dpkg-query -W -f='${Version}' printer-driver-escpr 2>/dev/null || true)"
if [ -z "$installed_driver_version" ] || ! dpkg --compare-versions "$installed_driver_version" ge "$ESC_PRR_MIN_VERSION"; then
  configured_candidate="$(apt-cache policy printer-driver-escpr 2>/dev/null | awk '/Candidate:/ {print $2; exit}')"
  if [ -z "$configured_candidate" ] || ! dpkg --compare-versions "$configured_candidate" ge "$ESC_PRR_MIN_VERSION"; then
    TEMP_SOURCE="/etc/apt/sources.list.d/primebook-escpr-forky.list"
    TEMP_PREF="/etc/apt/preferences.d/primebook-escpr-forky"
    cleanup_escpr_source() {
      rm -f "$TEMP_SOURCE" "$TEMP_PREF"
    }
    trap cleanup_escpr_source EXIT

    cat > "$TEMP_SOURCE" <<'SOURCE'
deb https://deb.debian.org/debian forky main
SOURCE
    cat > "$TEMP_PREF" <<'PREFERENCE'
Package: *
Pin: release n=forky
Pin-Priority: -1

Package: printer-driver-escpr
Pin: release n=forky
Pin-Priority: 1001
PREFERENCE

    echo "== Fetching the model-aware ARM64 ESC/P-R driver from Debian Forky =="
    apt-get update
    candidate="$(apt-cache policy printer-driver-escpr | awk '/Candidate:/ {print $2; exit}')"
    if [ -z "$candidate" ] || ! dpkg --compare-versions "$candidate" ge "$ESC_PRR_MIN_VERSION"; then
      echo "ERROR: Debian did not offer ESC/P-R $ESC_PRR_MIN_VERSION or newer for ARM64." >&2
      exit 1
    fi
    apt-get install -y printer-driver-escpr
    cleanup_escpr_source
    trap - EXIT
  else
    apt-get install -y printer-driver-escpr
  fi
fi

DRIVER_VERSION="$(dpkg-query -W -f='${Version}' printer-driver-escpr)"
if ! dpkg --compare-versions "$DRIVER_VERSION" ge "$ESC_PRR_MIN_VERSION"; then
  echo "ERROR: ESC/P-R $DRIVER_VERSION is too old for the L3110 model PPD; expected $ESC_PRR_MIN_VERSION or newer." >&2
  exit 1
fi

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

# Create an Epson-specific setup shortcut on both the XFCE desktop and menu.
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

# Remove temporary repository metadata. The next apt operation will use only
# the Debian suites configured by the user for their own system.
rm -rf /var/lib/apt/lists/*
apt-get clean

echo
echo "Printing stack installed for Debian ARM64."
echo "Epson ESC/P-R driver version: $DRIVER_VERSION (L3110 model PPD included)."
echo "Epson L3110 Series Setup shortcut created on the XFCE desktop and in the Applications menu."
echo "After start-all, open that shortcut to reach CUPS Administration → Add Printer."
echo "Scanner support: SANE epson2 backend; check visibility with: scanimage -L"
echo "CUPS admin URL: http://127.0.0.1:631/admin"
echo "Set a password for the desktop user before CUPS administration:"
echo "  proot-distro login --isolated debian -- passwd prime"
DEBIAN_PRINTING

echo
echo "USB caveat: Android does not expose arbitrary USB devices as normal Linux device nodes to PRoot."
echo "The L3110 has USB connectivity only; network printing requires a separate USB print server/host."
