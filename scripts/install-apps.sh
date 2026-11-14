#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

if ! command -v proot-distro >/dev/null 2>&1; then
  echo "proot-distro is missing. Run scripts/setup-termux.sh first." >&2
  exit 1
fi

INSTALL_OFFICE=0
case "${1:-}" in
  "") ;;
  --office) INSTALL_OFFICE=1 ;;
  *)
    echo "Usage: bash scripts/install-apps.sh [--office]" >&2
    exit 2
    ;;
esac

proot-distro login debian -- /usr/bin/env "INSTALL_OFFICE=$INSTALL_OFFICE" /bin/bash -s <<'DEBIAN_SCRIPT'
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

if [ "$(dpkg --print-architecture)" != "arm64" ]; then
  echo "Notice: this device's Debian architecture is $(dpkg --print-architecture), not arm64."
  echo "The package manager will choose packages for the detected architecture."
fi

echo "== Installing the lightweight desktop app bundle =="
apt-get update
apt-get install -y \
  firefox-esr \
  vlc mpv ffmpeg \
  geany \
  ristretto atril xarchiver galculator \
  xfce4-screenshooter xfce4-taskmanager \
  htop ncdu \
  pavucontrol pulseaudio-utils \
  xdg-utils \
  fonts-noto-color-emoji

if [ "$INSTALL_OFFICE" = "1" ]; then
  echo "== Installing optional office suite =="
  apt-get install -y libreoffice-writer libreoffice-calc
fi

# GUI apps such as VLC must not be run as root. Create a dedicated,
# unprivileged desktop account for the XFCE session and app launchers.
if ! id prime >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash prime
fi

PRIME_HOME="$(getent passwd prime | cut -d: -f6)"
if [ -z "$PRIME_HOME" ] || [ ! -d "$PRIME_HOME" ]; then
  echo "Could not resolve the home directory for user 'prime'." >&2
  exit 1
fi

DESKTOP_DIR="$PRIME_HOME/Desktop"
install -d -m 0755 -o prime -g prime "$DESKTOP_DIR"
install -d -m 0755 -o prime -g prime \
  "$PRIME_HOME/Downloads" "$PRIME_HOME/Documents" "$PRIME_HOME/Pictures" \
  "$PRIME_HOME/Music" "$PRIME_HOME/Videos"

write_launcher() {
  local filename="$1"
  local name="$2"
  local comment="$3"
  local command_line="$4"
  local icon="$5"
  local categories="$6"

  cat > "$DESKTOP_DIR/$filename" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Comment=$comment
Exec=$command_line
Icon=$icon
Terminal=false
Categories=$categories
StartupNotify=true
EOF
}

echo "== Creating desktop shortcuts for /home/prime/Desktop =="

write_launcher "firefox-esr.desktop" "Firefox ESR" "Browse the web" \
  "firefox-esr --new-window %u" "firefox-esr" "Network;WebBrowser;"
write_launcher "vlc.desktop" "VLC Media Player" "Play video and audio files" \
  "vlc %U" "vlc" "AudioVideo;Player;"
write_launcher "mpv.desktop" "MPV Media Player" "Lightweight video and audio player" \
  "mpv --force-window %F" "mpv" "AudioVideo;Player;"
write_launcher "thunar.desktop" "File Manager" "Browse files and folders" \
  "thunar %U" "org.xfce.thunar" "System;FileManager;"
write_launcher "xfce4-terminal.desktop" "Terminal" "Open a Linux terminal" \
  "xfce4-terminal" "utilities-terminal" "System;TerminalEmulator;"
write_launcher "geany.desktop" "Geany" "Lightweight code editor and IDE" \
  "geany %F" "geany" "Development;IDE;TextEditor;"
write_launcher "mousepad.desktop" "Text Editor" "Edit text files" \
  "mousepad %F" "accessories-text-editor" "Utility;TextEditor;"
write_launcher "ristretto.desktop" "Image Viewer" "View images" \
  "ristretto %F" "ristretto" "Graphics;Viewer;"
write_launcher "atril.desktop" "PDF Viewer" "Read PDF documents" \
  "atril %U" "atril" "Office;Viewer;"
write_launcher "xarchiver.desktop" "Archive Manager" "Create and extract archives" \
  "xarchiver" "xarchiver" "Utility;Archiving;"
write_launcher "galculator.desktop" "Calculator" "Scientific calculator" \
  "galculator" "galculator" "Utility;Calculator;"
write_launcher "xfce4-taskmanager.desktop" "System Monitor" "Inspect running processes and memory" \
  "xfce4-taskmanager" "utilities-system-monitor" "System;Monitor;"
write_launcher "xfce4-screenshooter.desktop" "Screenshot" "Capture the desktop" \
  "xfce4-screenshooter" "applets-screenshooter" "Utility;"
write_launcher "pavucontrol.desktop" "Audio Settings" "Configure PulseAudio volume" \
  "pavucontrol" "multimedia-volume-control" "AudioVideo;Settings;"

if [ "$INSTALL_OFFICE" = "1" ]; then
  write_launcher "libreoffice-writer.desktop" "LibreOffice Writer" "Write documents" \
    "libreoffice --writer" "libreoffice-writer" "Office;WordProcessor;"
  write_launcher "libreoffice-calc.desktop" "LibreOffice Calc" "Work with spreadsheets" \
    "libreoffice --calc" "libreoffice-calc" "Office;Spreadsheet;"
fi

chown -R prime:prime "$DESKTOP_DIR"
chmod 0755 "$DESKTOP_DIR"/*.desktop

# Ensure the desktop has a sensible icon layout when XFCE first starts.
install -d -m 0755 -o prime -g prime "$PRIME_HOME/.config"

apt-get clean
rm -rf /var/lib/apt/lists/*

echo
echo "App installation complete."
echo "Desktop account: prime"
echo "Desktop shortcuts: $DESKTOP_DIR"
echo "Start XFCE with: proot-distro login debian --user prime --shared-tmp"
DEBIAN_SCRIPT

echo
echo "Installed desktop apps and created the XFCE desktop shortcuts."
echo "Stop any existing root XFCE session, then restart with scripts/start-desktop.sh."
