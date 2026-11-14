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
  echo "Notice: detected Debian architecture: $(dpkg --print-architecture)"
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
  xdg-utils gvfs gvfs-backends xinput \
  fonts-noto-color-emoji \
  sudo

# Desktop polish packages vary between Debian releases. Install only those
# actually available in the configured repositories.
optional_packages=(
  arc-theme papirus-icon-theme fonts-cantarell
  xfce4-whiskermenu-plugin xfce4-docklike-plugin
  xfce4-pulseaudio-plugin xfce4-notifyd xfce4-clipman-plugin
  tumbler ffmpegthumbnailer
)
available_packages=()
for package in "${optional_packages[@]}"; do
  if apt-cache show "$package" >/dev/null 2>&1; then
    available_packages+=("$package")
  else
    echo "Optional package not available; skipping: $package"
  fi
done
if [ "${#available_packages[@]}" -gt 0 ]; then
  apt-get install -y "${available_packages[@]}"
fi

if [ "$INSTALL_OFFICE" = "1" ]; then
  apt-get install -y libreoffice-writer libreoffice-calc
fi

# Never run browsers or VLC in the root desktop session.
if ! id prime >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash prime
fi
# Use an explicit password-authenticated sudoers rule for prime. In PRoot,
# supplemental group membership may not be reflected in selected-user sessions.
install -d -m 0755 /etc/sudoers.d
printf '%s\\n' 'prime ALL=(ALL:ALL) ALL' > /etc/sudoers.d/prime
chown root:root /etc/sudoers.d/prime
chmod 0440 /etc/sudoers.d/prime
visudo -c
PRIME_HOME="$(getent passwd prime | cut -d: -f6)"
[ -n "$PRIME_HOME" ] && [ -d "$PRIME_HOME" ] || { echo "Could not resolve prime home." >&2; exit 1; }

DESKTOP_DIR="$PRIME_HOME/Desktop"
install -d -m 0755 -o prime -g prime "$DESKTOP_DIR"
install -d -m 0755 -o prime -g prime \
  "$PRIME_HOME/Downloads" "$PRIME_HOME/Documents" "$PRIME_HOME/Pictures" \
  "$PRIME_HOME/Music" "$PRIME_HOME/Videos"

write_launcher() {
  local filename="$1" name="$2" comment="$3" command_line="$4" icon="$5" categories="$6"
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

write_launcher firefox-esr.desktop "Firefox ESR" "Browse the web" "firefox-esr --new-window %u" firefox-esr "Network;WebBrowser;"
write_launcher vlc.desktop "VLC Media Player" "Play video and audio files" "vlc %U" vlc "AudioVideo;Player;"
write_launcher mpv.desktop "MPV Media Player" "Lightweight media player" "mpv --force-window %F" mpv "AudioVideo;Player;"
write_launcher thunar.desktop "File Manager" "Browse files and folders" "thunar %U" org.xfce.thunar "System;FileManager;"
write_launcher xfce4-terminal.desktop "Terminal" "Open a Linux terminal" xfce4-terminal utilities-terminal "System;TerminalEmulator;"
write_launcher geany.desktop "Geany" "Lightweight code editor" "geany %F" geany "Development;IDE;TextEditor;"
write_launcher mousepad.desktop "Text Editor" "Edit text files" "mousepad %F" accessories-text-editor "Utility;TextEditor;"
write_launcher ristretto.desktop "Image Viewer" "View images" "ristretto %F" ristretto "Graphics;Viewer;"
write_launcher atril.desktop "PDF Viewer" "Read PDF documents" "atril %U" atril "Office;Viewer;"
write_launcher xarchiver.desktop "Archive Manager" "Create and extract archives" xarchiver xarchiver "Utility;Archiving;"
write_launcher galculator.desktop "Calculator" "Scientific calculator" galculator galculator "Utility;Calculator;"
write_launcher xfce4-taskmanager.desktop "System Monitor" "Inspect processes and memory" xfce4-taskmanager utilities-system-monitor "System;Monitor;"
write_launcher xfce4-screenshooter.desktop "Screenshot" "Capture the desktop" xfce4-screenshooter applets-screenshooter "Utility;"
write_launcher pavucontrol.desktop "Audio Settings" "Configure audio volume" pavucontrol multimedia-volume-control "AudioVideo;Settings;"

if [ "$INSTALL_OFFICE" = "1" ]; then
  write_launcher libreoffice-writer.desktop "LibreOffice Writer" "Write documents" "libreoffice --writer" libreoffice-writer "Office;WordProcessor;"
  write_launcher libreoffice-calc.desktop "LibreOffice Calc" "Work with spreadsheets" "libreoffice --calc" libreoffice-calc "Office;Spreadsheet;"
fi

chown -R prime:prime "$DESKTOP_DIR"
chmod 0755 "$DESKTOP_DIR"/*.desktop

# Create a branded dark SVG wallpaper without downloading external assets.
install -d -m 0755 /usr/share/backgrounds/termux-debian-x11
cat > /usr/share/backgrounds/termux-debian-x11/primebook-midnight.svg <<'WALLPAPER'
<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080">
<defs>
<linearGradient id="b" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#080d1b"/><stop offset=".55" stop-color="#111b32"/><stop offset="1" stop-color="#111126"/></linearGradient>
<radialGradient id="c"><stop stop-color="#00c6c8" stop-opacity=".28"/><stop offset="1" stop-color="#00c6c8" stop-opacity="0"/></radialGradient>
<pattern id="g" width="72" height="72" patternUnits="userSpaceOnUse"><path d="M72 0H0V72" fill="none" stroke="#a9c9e7" stroke-opacity=".07"/></pattern>
</defs>
<rect width="1920" height="1080" fill="url(#b)"/><ellipse cx="1450" cy="300" rx="700" ry="520" fill="url(#c)"/><rect width="1920" height="1080" fill="url(#g)"/>
<g fill="none" stroke="#55d4d0" stroke-opacity=".25" stroke-width="2"><circle cx="1450" cy="390" r="180"/><circle cx="1450" cy="390" r="250"/><circle cx="1450" cy="390" r="320"/><path d="M980 0L1920 940M1200 0L1920 720M1920 180L1020 1080M0 820L600 1080"/></g>
<g fill="#d8f7f5" opacity=".4"><circle cx="1450" cy="390" r="4"/><circle cx="1220" cy="250" r="2"/><circle cx="1670" cy="540" r="2"/></g>
</svg>
WALLPAPER
chmod 0644 /usr/share/backgrounds/termux-debian-x11/primebook-midnight.svg

# Persistent first-login XFCE appearance settings. The autostart helper runs
# as prime after the Xfconf session has started.
install -d -m 0755 -o prime -g prime "$PRIME_HOME/.config/autostart"
cat > /usr/local/bin/primebook-xfce-tune <<'TUNE'
#!/bin/bash
set -u
sleep 5
set_setting() {
  xfconf-query -c "$1" -p "$2" --create -t "$3" -s "$4" >/dev/null 2>&1 || true
}
GTK_THEME=Adwaita
[ -d /usr/share/themes/Arc-Dark ] && GTK_THEME=Arc-Dark
ICON_THEME=Adwaita
[ -d /usr/share/icons/Papirus-Dark ] && ICON_THEME=Papirus-Dark
FONT="DejaVu Sans 10"
fc-match Cantarell 2>/dev/null | grep -qi Cantarell && FONT="Cantarell 10"

set_setting xsettings /Net/ThemeName string "$GTK_THEME"
set_setting xsettings /Net/IconThemeName string "$ICON_THEME"
set_setting xsettings /Net/FontName string "$FONT"
set_setting xsettings /Gtk/FontName string "$FONT"
set_setting xfwm4 /general/theme string "$GTK_THEME"
set_setting xfwm4 /general/title_font string "DejaVu Sans Bold 10"
set_setting xfwm4 /general/use_compositing bool false
set_setting xfce4-desktop /desktop-icons/icon-size uint 48
set_setting xfce4-desktop /backdrop/screen0/monitor0/workspace0/last-image string "/usr/share/backgrounds/termux-debian-x11/primebook-midnight.svg"
set_setting xfce4-desktop /backdrop/screen0/monitor0/workspace0/image-style int 5
set_setting xfce4-panel /panels/panel-1/position string "p=8;x=0;y=0"
set_setting xfce4-panel /panels/panel-1/size uint 44
set_setting xfce4-panel /panels/panel-1/length uint 100
set_setting xfce4-panel /panels/panel-1/position-locked bool true
set_setting xfce4-panel /panels/panel-1/autohide-behavior uint 0
set_setting xfce4-panel /panels/panel-1/icon-size uint 24
xfce4-panel -r >/dev/null 2>&1 || true
xfdesktop --reload >/dev/null 2>&1 || true
TUNE
chmod 0755 /usr/local/bin/primebook-xfce-tune
chown root:root /usr/local/bin/primebook-xfce-tune

cat > "$PRIME_HOME/.config/autostart/primebook-xfce-tune.desktop" <<'AUTOSTART'
[Desktop Entry]
Type=Application
Version=1.0
Name=PrimeBook Desktop Polish
Comment=Apply the lightweight dark theme, wallpaper and panel layout
Exec=/usr/local/bin/primebook-xfce-tune
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
NoDisplay=true
AUTOSTART
chown prime:prime "$PRIME_HOME/.config/autostart/primebook-xfce-tune.desktop"
chmod 0644 "$PRIME_HOME/.config/autostart/primebook-xfce-tune.desktop"

apt-get clean
rm -rf /var/lib/apt/lists/*
echo
echo "Desktop apps, shortcuts, wallpaper and XFCE polish installed for user prime."
DEBIAN_SCRIPT

echo
echo "Desktop application bundle and PrimeBook XFCE customization installed."
echo "Restart the desktop to apply the theme and wallpaper."
