#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
command -v proot-distro >/dev/null 2>&1 || { echo "Run scripts/setup-termux.sh first." >&2; exit 1; }
proot-distro login debian -- /bin/bash -s <<'DEBIAN_PRINTING'
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
echo "== Installing CUPS, Epson ESC/P-R, Gutenprint and scanner tools =="
apt-get update
apt-get install -y cups cups-client cups-filters cups-ipp-utils printer-driver-escpr printer-driver-gutenprint usbutils sane-utils
if apt-cache show sane-airscan >/dev/null 2>&1; then apt-get install -y sane-airscan; else echo "sane-airscan not available in this Debian repository; skipping."; fi

if ! id prime >/dev/null 2>&1; then useradd --create-home --shell /bin/bash prime; fi
getent group lpadmin >/dev/null 2>&1 && usermod -aG lpadmin prime || true
getent group lp >/dev/null 2>&1 && usermod -aG lp prime || true

PRIME_HOME="$(getent passwd prime | cut -d: -f6)"
DESKTOP_DIR="$PRIME_HOME/Desktop"
install -d -m 0755 -o prime -g prime "$DESKTOP_DIR"
cat > "$DESKTOP_DIR/printer-settings.desktop" <<'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Printer Settings (CUPS)
Comment=Open local printer setup and status
Exec=firefox-esr --new-window http://127.0.0.1:631
Icon=printer
Terminal=false
Categories=Settings;HardwareSettings;
StartupNotify=true
DESKTOP
chown prime:prime "$DESKTOP_DIR/printer-settings.desktop"
chmod 0755 "$DESKTOP_DIR/printer-settings.desktop"
apt-get clean
rm -rf /var/lib/apt/lists/*
echo
echo "Printing stack installed."
echo "Epson ESC/P-R and Gutenprint drivers are installed for their supported models."
echo "CUPS admin: http://127.0.0.1:631"
echo "Set a password for the desktop user before CUPS administration:"
echo "  proot-distro login debian -- passwd prime"
DEBIAN_PRINTING
echo
echo "Note: Android does not expose arbitrary USB devices as normal Linux device nodes to PRoot."
echo "For reliable printing from Debian, prefer a printer connected over Wi-Fi/Ethernet."
