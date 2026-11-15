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

proot-distro login --isolated debian -- /usr/bin/env "INSTALL_OFFICE=$INSTALL_OFFICE" /bin/bash -s <<'DEBIAN_SCRIPT'
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

if [ "$(dpkg --print-architecture)" != "arm64" ]; then
  echo "Notice: detected Debian architecture: $(dpkg --print-architecture)"
fi

echo "== Installing the lightweight desktop app bundle =="
apt-get update
apt-get install -y \
  firefox-esr \
  gdebi \
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
printf '%s\n' 'prime ALL=(ALL:ALL) ALL' > /etc/sudoers.d/prime
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

# Install a permanent XFCE launcher for OpenCode Desktop when its ARM64 .deb
# is present. The wrapper keeps logs in Downloads and avoids a blocked menu
# launch caused by Electron sandbox/GPU assumptions under PRoot.
if [ -x /opt/OpenCode/ai.opencode ]; then
  cat > /usr/local/bin/primebook-opencode <<'OPENCODE_LAUNCHER'
#!/bin/bash
set -u
mkdir -p "$HOME/Downloads"
LOG_FILE="$HOME/Downloads/opencode-desktop.log"
printf '\n===== OpenCode launch: %s =====\n' "$(date -Is)" >> "$LOG_FILE"
nohup env DISPLAY="${DISPLAY:-:0}" /opt/OpenCode/ai.opencode \
  --no-sandbox --disable-gpu --disable-dev-shm-usage --ozone-platform=x11 \
  "$@" >> "$LOG_FILE" 2>&1 < /dev/null &
OPENCODE_LAUNCHER
  chmod 0755 /usr/local/bin/primebook-opencode
  chown root:root /usr/local/bin/primebook-opencode

  install -d -m 0755 -o prime -g prime "$PRIME_HOME/.local/share/applications"
  cat > "$PRIME_HOME/.local/share/applications/opencode-desktop.desktop" <<'OPENCODE_DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=OpenCode
GenericName=AI Coding Agent
Comment=Open OpenCode Desktop
Exec=/usr/local/bin/primebook-opencode %U
Icon=utilities-terminal
Terminal=false
Categories=Development;IDE;
StartupNotify=false
OPENCODE_DESKTOP
  chown prime:prime "$PRIME_HOME/.local/share/applications/opencode-desktop.desktop"
  chmod 0644 "$PRIME_HOME/.local/share/applications/opencode-desktop.desktop"

  cat > "$PRIME_HOME/.local/share/applications/ai.opencode.desktop.desktop" <<'OPENCODE_HIDDEN'
[Desktop Entry]
Type=Application
Hidden=true
OPENCODE_HIDDEN
  chown prime:prime "$PRIME_HOME/.local/share/applications/ai.opencode.desktop.desktop"
  chmod 0644 "$PRIME_HOME/.local/share/applications/ai.opencode.desktop.desktop"
  cat > "$DESKTOP_DIR/OpenCode.desktop" <<'OPENCODE_SHORTCUT'
[Desktop Entry]
Version=1.0
Type=Application
Name=OpenCode
Comment=Launch OpenCode Desktop
Exec=/usr/local/bin/primebook-opencode %U
Icon=utilities-terminal
Terminal=false
Categories=Development;IDE;
StartupNotify=false
OPENCODE_SHORTCUT
  chown prime:prime "$DESKTOP_DIR/OpenCode.desktop"
  chmod 0644 "$DESKTOP_DIR/OpenCode.desktop"
fi

# GDebi's normal Install action delegates privilege elevation to PolicyKit.
# That hand-off can fail in a PRoot desktop without a normal polkit session.
# Launch the GTK frontend from an interactive terminal with sudo already
# authenticated, capture stdout/stderr live, and retain a persistent log.
install -d -m 0755 /usr/local/bin
cat > /usr/local/bin/primebook-gdebi-launcher <<'GDEBI_WRAPPER'
#!/bin/bash
set -u
LOG_DIR="${HOME}/Documents"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/gdebi-install.log"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo
echo "===== GDebi session: $(date -Is) ====="
echo "Desktop user: $(id -un)"
echo "Debian architecture: $(dpkg --print-architecture)"
echo "Log file: $LOG_FILE"

if [ ! -x /usr/bin/gdebi-gtk ]; then
  echo "ERROR: /usr/bin/gdebi-gtk is missing. Reinstall the gdebi package."
  exit 127
fi
if ! command -v sudo >/dev/null 2>&1; then
  echo "ERROR: sudo is missing. Re-run the desktop app installer."
  exit 127
fi
if [ "$#" -gt 0 ]; then
  for package_file in "$@"; do
    if [ -f "$package_file" ]; then
      echo
      echo "--- Package metadata: $package_file ---"
      package_arch="$(dpkg-deb -f "$package_file" Architecture 2>/dev/null || true)"
      dpkg-deb -f "$package_file" Package Version Architecture 2>&1 || true
      case "$package_arch" in
        arm64|all) ;;
        *)
          echo "ERROR: This Debian environment is ARM64. Refusing package architecture: ${package_arch:-unknown}"
          echo "Use an arm64 or architecture-independent (all) .deb package."
          exit 2
          ;;
      esac
    else
      echo "NOTE: not a local file: $package_file"
    fi
  done
fi

echo
echo "Requesting Debian administrator authentication..."
if ! sudo -v; then
  echo "ERROR: sudo authentication failed. No package was installed."
  exit 1
fi

echo "Starting GDebi GTK with administrator privileges."
echo "This bypasses the PolicyKit hand-off that can fail under PRoot."
echo "Keep this terminal open while GDebi is running."
DISPLAY_VALUE="${DISPLAY:-:0}"
if [ -z "$DISPLAY_VALUE" ]; then
  echo "ERROR: DISPLAY is not set. Open GDebi from the running XFCE desktop."
  exit 1
fi
GUI_ENV=("DISPLAY=$DISPLAY_VALUE")
if [ -n "${XAUTHORITY:-}" ] && [ -r "$XAUTHORITY" ]; then
  GUI_ENV+=("XAUTHORITY=$XAUTHORITY")
fi
set +e
sudo -H env "${GUI_ENV[@]}" /usr/bin/gdebi-gtk "$@"
status=$?
set -e

if [ "$status" -eq 0 ] && [ "$#" -gt 0 ] && [ -x /usr/local/bin/primebook-deb-postinstall ]; then
  echo
  echo "Refreshing desktop launchers for the installed ARM64 package..."
  /usr/local/bin/primebook-deb-postinstall "$@" || echo "NOTE: automatic launcher refresh reported a warning; see this log."
fi
echo
echo "GDebi GTK exited with status: $status"
echo "Any terminal output has been appended to: $LOG_FILE"
echo "===== End GDebi session: $(date -Is) ====="
exit "$status"
GDEBI_WRAPPER
chmod 0755 /usr/local/bin/primebook-gdebi-launcher
chown root:root /usr/local/bin/primebook-gdebi-launcher

# Shared Electron/Chromium launcher for ARM64 GUI packages under PRoot.
cat > /usr/local/bin/primebook-electron-launcher <<'ELECTRON_WRAPPER'
#!/bin/bash
set -u
APP="$1"
shift
[ -x "$APP" ] || { echo "Missing app binary: $APP" >&2; exit 127; }
mkdir -p "$HOME/Downloads"
APP_NAME="$(basename "$APP")"
case "$APP" in
  /opt/OpenCode/*) LOG_FILE="$HOME/Downloads/opencode-desktop.log" ;;
  *) LOG_FILE="$HOME/Downloads/${APP_NAME}-desktop.log" ;;
esac
printf '\n===== %s launch: %s =====\n' "$APP_NAME" "$(date -Is)" >> "$LOG_FILE"
nohup env DISPLAY="${DISPLAY:-:0}" "$APP" --no-sandbox --disable-gpu --disable-dev-shm-usage --ozone-platform=x11 "$@" >> "$LOG_FILE" 2>&1 < /dev/null &
ELECTRON_WRAPPER
chmod 0755 /usr/local/bin/primebook-electron-launcher
chown root:root /usr/local/bin/primebook-electron-launcher

# Rebuild per-user launchers after installing a local ARM64 .deb package.
cat > /usr/local/bin/primebook-deb-postinstall <<'DEB_POSTINSTALL'
#!/bin/bash
set -Eeuo pipefail
[ "$(dpkg --print-architecture)" = "arm64" ] || exit 2
[ "$(id -un)" = "prime" ] || { echo "Run as prime." >&2; exit 2; }
mkdir -p "$HOME/.local/share/applications"
for deb in "$@"; do
  [ -f "$deb" ] || continue
  pkg="$(dpkg-deb -f "$deb" Package)"
  arch="$(dpkg-deb -f "$deb" Architecture)"
  case "$arch" in arm64|all) ;; *) echo "Refusing incompatible package architecture: $arch"; continue;; esac
  [ "$(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null || true)" = "install ok installed" ] || continue
  while IFS= read -r desktop_file; do
    [ -f "$desktop_file" ] || continue
    desktop_id="$(basename "$desktop_file")"
    if [ "$desktop_id" = "ai.opencode.desktop.desktop" ]; then
      printf '[Desktop Entry]\nType=Application\nHidden=true\n' > "$HOME/.local/share/applications/$desktop_id"
      continue
    fi
    exec_line="$(sed -n 's/^Exec=//p' "$desktop_file" | head -n 1)"
    [ -n "$exec_line" ] || continue
    read -r app_bin rest <<< "$exec_line"
    app_bin="${app_bin#\"}"; app_bin="${app_bin%\"}"
    case "$app_bin" in /*) ;; *) continue;; esac
    app_dir="$(dirname "$app_bin")"
    if [ -x "$app_bin" ] && [ -x "$app_dir/chrome-sandbox" ] && [ -d "$app_dir/resources" ]; then
      cp "$desktop_file" "$HOME/.local/share/applications/$desktop_id"
      escaped_bin="$(printf '%s' "$app_bin" | sed 's/[&|]/\\&/g')"
      sed -i "s|^Exec=.*|Exec=/usr/local/bin/primebook-electron-launcher \"$escaped_bin\" $rest|" "$HOME/.local/share/applications/$desktop_id"
      echo "Added Electron compatibility launcher: $desktop_id"
    fi
  done < <(dpkg-query -L "$pkg" | grep -E '^/usr/share/applications/.*\.desktop$' || true)
done
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi
DEB_POSTINSTALL
chmod 0755 /usr/local/bin/primebook-deb-postinstall
chown root:root /usr/local/bin/primebook-deb-postinstall

# One supported path for future local ARM64 Debian package installs.
cat > /usr/local/bin/primebook-install-deb <<'INSTALL_DEB'
#!/bin/bash
set -Eeuo pipefail
if [ "$#" -lt 1 ]; then echo "Usage: primebook-install-deb /path/to/package.deb"; exit 2; fi
for deb in "$@"; do
  [ -f "$deb" ] || { echo "File not found: $deb"; exit 2; }
  arch="$(dpkg-deb -f "$deb" Architecture)"
  case "$arch" in arm64|all) ;; *) echo "Refusing $arch package: $deb (this Debian is ARM64)"; exit 2;; esac
done
sudo gdebi "$@"
if [ -x /usr/local/bin/primebook-deb-postinstall ]; then
  /usr/local/bin/primebook-deb-postinstall "$@"
fi
INSTALL_DEB
chmod 0755 /usr/local/bin/primebook-install-deb
chown root:root /usr/local/bin/primebook-install-deb

# Override the system GDebi desktop entry for prime. Launching through
# xfce4-terminal keeps the authentication prompt and install output visible.
APP_DIR="$PRIME_HOME/.local/share/applications"
install -d -m 0755 -o prime -g prime "$APP_DIR"
cat > "$APP_DIR/gdebi.desktop" <<'GDEBI_DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=GDebi Package Installer
GenericName=Package Installer
Comment=Install Debian packages with a visible diagnostic log
Exec=xfce4-terminal --disable-server --hold --title=GDebi-Install-Log --execute /usr/local/bin/primebook-gdebi-launcher %f
Icon=application-x-deb
Terminal=false
Categories=System;PackageManager;
MimeType=application/vnd.debian.binary-package;
StartupNotify=false
GDEBI_DESKTOP
chown prime:prime "$APP_DIR/gdebi.desktop"
chmod 0644 "$APP_DIR/gdebi.desktop"
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi
if command -v runuser >/dev/null 2>&1 && command -v xdg-mime >/dev/null 2>&1; then
  runuser -u prime -- env HOME="$PRIME_HOME" xdg-mime default gdebi.desktop application/vnd.debian.binary-package || true
fi
cat > "$DESKTOP_DIR/GDebi Package Installer.desktop" <<'GDEBI_SHORTCUT'
[Desktop Entry]
Version=1.0
Type=Application
Name=GDebi Package Installer
Comment=Install Debian packages and view the live log
Exec=xfce4-terminal --disable-server --hold --title=GDebi-Install-Log --execute /usr/local/bin/primebook-gdebi-launcher
Icon=application-x-deb
Terminal=false
Categories=System;PackageManager;
StartupNotify=false
GDEBI_SHORTCUT
chown prime:prime "$DESKTOP_DIR/GDebi Package Installer.desktop"
chmod 0644 "$DESKTOP_DIR/GDebi Package Installer.desktop"

if [ "$INSTALL_OFFICE" = "1" ]; then
  write_launcher libreoffice-writer.desktop "LibreOffice Writer" "Write documents" "libreoffice --writer" libreoffice-writer "Office;WordProcessor;"
  write_launcher libreoffice-calc.desktop "LibreOffice Calc" "Work with spreadsheets" "libreoffice --calc" libreoffice-calc "Office;Spreadsheet;"
fi

chown -R prime:prime "$DESKTOP_DIR"
chmod 0755 "$DESKTOP_DIR"/*.desktop

# Create a polished, futuristic PrimeBook wallpaper using a local SVG asset.
# No network download or external image dependency is required.
install -d -m 0755 /usr/share/backgrounds/termux-debian-x11
cat > /usr/share/backgrounds/termux-debian-x11/primebook-midnight.svg <<'WALLPAPER'
<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080">
<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
    <stop stop-color="#070b16"/><stop offset=".52" stop-color="#0d1428"/><stop offset="1" stop-color="#17112b"/>
  </linearGradient>
  <radialGradient id="cyan">
    <stop stop-color="#16d9d2" stop-opacity=".32"/><stop offset=".48" stop-color="#16d9d2" stop-opacity=".09"/><stop offset="1" stop-color="#16d9d2" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="violet">
    <stop stop-color="#956cff" stop-opacity=".24"/><stop offset="1" stop-color="#956cff" stop-opacity="0"/>
  </radialGradient>
  <linearGradient id="orb" x1="0" y1="0" x2="1" y2="1">
    <stop stop-color="#4cf1dd" stop-opacity=".72"/><stop offset=".52" stop-color="#5579db" stop-opacity=".22"/><stop offset="1" stop-color="#a36cff" stop-opacity=".1"/>
  </linearGradient>
  <linearGradient id="line" x1="0" y1="0" x2="1" y2="1">
    <stop stop-color="#6cefe0" stop-opacity="0"/><stop offset=".48" stop-color="#6cefe0" stop-opacity=".55"/><stop offset="1" stop-color="#a58bff" stop-opacity="0"/>
  </linearGradient>
  <pattern id="grid" width="72" height="72" patternUnits="userSpaceOnUse">
    <path d="M72 0H0V72" fill="none" stroke="#b8d7f3" stroke-opacity=".055" stroke-width="1"/>
    <circle cx="0" cy="0" r="1.4" fill="#9bdedb" fill-opacity=".2"/>
  </pattern>
</defs>
<rect width="1920" height="1080" fill="url(#bg)"/>
<ellipse cx="1430" cy="410" rx="850" ry="640" fill="url(#cyan)"/>
<ellipse cx="1710" cy="870" rx="620" ry="470" fill="url(#violet)"/>
<rect width="1920" height="1080" fill="url(#grid)"/>
<g opacity=".52" fill="none" stroke="url(#line)" stroke-width="2">
  <path d="M820 -80C1120 180 1020 430 1350 510S1740 670 2020 1030"/>
  <path d="M1040 -100C1310 140 1210 420 1500 510S1790 720 1980 930"/>
  <path d="M850 1180C1100 870 1190 760 1470 720S1760 480 1950 230"/>
</g>
<g transform="translate(1430 465)" fill="none">
  <circle r="335" stroke="#7fece0" stroke-opacity=".10" stroke-width="1.5"/>
  <circle r="274" stroke="#7fece0" stroke-opacity=".16" stroke-width="1.5" stroke-dasharray="3 14"/>
  <circle r="214" stroke="#a58bff" stroke-opacity=".2" stroke-width="1.5"/>
  <circle r="154" stroke="url(#orb)" stroke-opacity=".52" stroke-width="2"/>
  <path d="M-440 0H440M0 -440V440" stroke="#a8d9e8" stroke-opacity=".10" stroke-width="1"/>
  <path d="M-310 -310L310 310M310 -310L-310 310" stroke="#a8d9e8" stroke-opacity=".075" stroke-width="1"/>
  <ellipse rx="420" ry="150" transform="rotate(-28)" stroke="#64e8dc" stroke-opacity=".27" stroke-width="2"/>
  <ellipse rx="360" ry="112" transform="rotate(34)" stroke="#a18bff" stroke-opacity=".23" stroke-width="2"/>
  <circle r="92" fill="url(#orb)" stroke="#98f5e8" stroke-opacity=".28" stroke-width="1.5"/>
  <circle r="11" fill="#b5fff0" fill-opacity=".9" stroke="none"/>
  <circle cx="305" cy="-288" r="5" fill="#85f4e8" stroke="none"/>
  <circle cx="-390" cy="115" r="4" fill="#a88cff" stroke="none"/>
  <circle cx="360" cy="214" r="3" fill="#b8fff4" stroke="none"/>
</g>
<g fill="#d7f8f4" opacity=".42">
  <circle cx="1080" cy="210" r="2"/><circle cx="1740" cy="210" r="2"/>
  <circle cx="1810" cy="610" r="2"/><circle cx="1220" cy="830" r="2"/>
  <circle cx="1510" cy="930" r="2"/><circle cx="990" cy="610" r="1.5"/>
</g>
<path d="M110 760H390" stroke="#54e4d6" stroke-opacity=".62" stroke-width="3"/>
<text x="110" y="835" fill="#edf7ff" font-family="Cantarell,Inter,Arial,sans-serif" font-size="58" font-weight="700" letter-spacing="9">PRIMEBOOK</text>
<text x="114" y="882" fill="#9eb5cc" font-family="Cantarell,Inter,Arial,sans-serif" font-size="17" letter-spacing="5">IMMERSIVE COMPUTING WORKSPACE</text>
<text x="114" y="932" fill="#7188a6" font-family="Cantarell,Inter,Arial,sans-serif" font-size="15" letter-spacing="2">BUILD  ·  EXPLORE  ·  CREATE</text>
</svg>
WALLPAPER
chmod 0644 /usr/share/backgrounds/termux-debian-x11/primebook-midnight.svg

# Persistent first-login XFCE appearance settings. The helper changes
# only per-user Xfconf appearance and panel-item properties; it does not
# alter Debian services, CUPS, audio, networking or X11 startup.
install -d -m 0755 -o prime -g prime "$PRIME_HOME/.config/autostart"
cat > /usr/local/bin/primebook-xfce-tune <<'TUNE'
#!/bin/bash
set -u
sleep 5

set_setting() {
  xfconf-query -c "$1" -p "$2" --create -t "$3" -s "$4" >/dev/null 2>&1 || true
}
set_panel_color() {
  local panel="$1"
  # Xfce stores panel background RGB as three uint16 values (0..65535).
  xfconf-query -c xfce4-panel -p "/panels/$panel/background-color" --create -a \
    -t uint -s 2300 -t uint -s 3300 -t uint -s 6200 >/dev/null 2>&1 || true
  set_setting xfce4-panel "/panels/$panel/background-alpha" uint 96
}

# A crisp dark theme with high-contrast icons and readable typography.
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
set_setting xsettings /Net/CursorThemeName string "Adwaita"
set_setting xsettings /Net/CursorThemeSize uint 24
set_setting xfwm4 /general/theme string "$GTK_THEME"
set_setting xfwm4 /general/title_font string "Cantarell Bold 10"
# Keep the compositor disabled: this is more reliable on Termux:X11/PRoot.
set_setting xfwm4 /general/use_compositing bool false

# Calm desktop with the custom PrimeBook orbital wallpaper.
set_setting xfce4-desktop /desktop-icons/icon-size uint 44
set_setting xfce4-desktop /desktop-icons/font-name string "$FONT"
set_setting xfce4-desktop /backdrop/screen0/monitor0/workspace0/last-image string "/usr/share/backgrounds/termux-debian-x11/primebook-midnight.svg"
set_setting xfce4-desktop /backdrop/screen0/monitor0/workspace0/image-style int 5

# Retain the current panel and every panel item; refine only their appearance.
set_setting xfce4-panel /panels/dark-mode bool true
set_setting xfce4-panel /panels/panel-1/position string "p=12;x=0;y=0"
set_setting xfce4-panel /panels/panel-1/size uint 52
set_setting xfce4-panel /panels/panel-1/length uint 100
set_setting xfce4-panel /panels/panel-1/position-locked bool true
set_setting xfce4-panel /panels/panel-1/autohide-behavior uint 0
set_setting xfce4-panel /panels/panel-1/icon-size uint 28
set_setting xfce4-panel /panels/panel-1/background-style uint 1
set_setting xfce4-panel /panels/panel-1/enter-opacity uint 100
set_setting xfce4-panel /panels/panel-1/leave-opacity uint 100
set_panel_color panel-1

# Detect existing panel plugins by their IDs. No item is added, removed or
# reordered, so the existing launchers and taskbar remain intact.
# Read the plugin IDs and their types directly from Xfconf. This works
# across Xfce versions without assuming the serialized array display format.
while read -r plugin_path plugin_type; do
  [[ "$plugin_path" =~ ^/plugins/plugin-([0-9]+)$ ]] || continue
  id="${BASH_REMATCH[1]}"
  case "$plugin_type" in
    applicationsmenu|whiskermenu)
      set_setting xfce4-panel "/plugins/plugin-$id/show-button-title" bool false
      set_setting xfce4-panel "/plugins/plugin-$id/show-menu-icons" bool true
      set_setting xfce4-panel "/plugins/plugin-$id/show-tooltips" bool true
      ;;
    tasklist)
      set_setting xfce4-panel "/plugins/plugin-$id/flat-buttons" bool true
      set_setting xfce4-panel "/plugins/plugin-$id/show-labels" bool false
      set_setting xfce4-panel "/plugins/plugin-$id/show-handle" bool false
      set_setting xfce4-panel "/plugins/plugin-$id/show-tooltips" bool true
      set_setting xfce4-panel "/plugins/plugin-$id/grouping" bool true
      ;;
    systray)
      set_setting xfce4-panel "/plugins/plugin-$id/icon-size" uint 22
      set_setting xfce4-panel "/plugins/plugin-$id/single-row" bool true
      ;;
    clock)
      set_setting xfce4-panel "/plugins/plugin-$id/mode" uint 2
      set_setting xfce4-panel "/plugins/plugin-$id/digital-format" string "%a %d %b  %H:%M"
      set_setting xfce4-panel "/plugins/plugin-$id/tooltip-format" string "%A, %d %B %Y"
      ;;
  esac
done < <(xfconf-query -c xfce4-panel -lv 2>/dev/null || true)

xfce4-panel -r >/dev/null 2>&1 || true
xfdesktop --reload >/dev/null 2>&1 || true
TUNE
chmod 0755 /usr/local/bin/primebook-xfce-tune
chown root:root /usr/local/bin/primebook-xfce-tune

cat > "$PRIME_HOME/.config/autostart/primebook-xfce-tune.desktop" <<'AUTOSTART'
[Desktop Entry]
Type=Application
Version=1.0
Name=PrimeBook Neo Desktop
Comment=Apply the PrimeBook dark interface, orbital wallpaper and refined taskbar
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
echo "Desktop apps, GDebi diagnostics, ARM64 .deb integration and panel layout installed."
echo "GDebi output is saved to /home/prime/Documents/gdebi-install.log."
echo "OpenCode launcher is installed when /opt/OpenCode/ai.opencode exists; its log is /home/prime/Downloads/opencode-desktop.log."
echo "Restart the desktop to refresh application menus and the updated taskbar layout."
 || true)
done

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi
DEB_POSTINSTALL
chmod 0755 /usr/local/bin/primebook-deb-postinstall
chown root:root /usr/local/bin/primebook-deb-postinstall

# Override the system GDebi desktop entry for prime. Launching through
# xfce4-terminal keeps the authentication prompt and install output visible.
APP_DIR="$PRIME_HOME/.local/share/applications"
install -d -m 0755 -o prime -g prime "$APP_DIR"
cat > "$APP_DIR/gdebi.desktop" <<'GDEBI_DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=GDebi Package Installer
GenericName=Package Installer
Comment=Install Debian packages with a visible diagnostic log
Exec=xfce4-terminal --disable-server --hold --title=GDebi-Install-Log --execute /usr/local/bin/primebook-gdebi-launcher %f
Icon=application-x-deb
Terminal=false
Categories=System;PackageManager;
MimeType=application/vnd.debian.binary-package;
StartupNotify=false
GDEBI_DESKTOP
chown prime:prime "$APP_DIR/gdebi.desktop"
chmod 0644 "$APP_DIR/gdebi.desktop"
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi
if command -v runuser >/dev/null 2>&1 && command -v xdg-mime >/dev/null 2>&1; then
  runuser -u prime -- env HOME="$PRIME_HOME" xdg-mime default gdebi.desktop application/vnd.debian.binary-package || true
fi
cat > "$DESKTOP_DIR/GDebi Package Installer.desktop" <<'GDEBI_SHORTCUT'
[Desktop Entry]
Version=1.0
Type=Application
Name=GDebi Package Installer
Comment=Install Debian packages and view the live log
Exec=xfce4-terminal --disable-server --hold --title=GDebi-Install-Log --execute /usr/local/bin/primebook-gdebi-launcher
Icon=application-x-deb
Terminal=false
Categories=System;PackageManager;
StartupNotify=false
GDEBI_SHORTCUT
chown prime:prime "$DESKTOP_DIR/GDebi Package Installer.desktop"
chmod 0644 "$DESKTOP_DIR/GDebi Package Installer.desktop"

if [ "$INSTALL_OFFICE" = "1" ]; then
  write_launcher libreoffice-writer.desktop "LibreOffice Writer" "Write documents" "libreoffice --writer" libreoffice-writer "Office;WordProcessor;"
  write_launcher libreoffice-calc.desktop "LibreOffice Calc" "Work with spreadsheets" "libreoffice --calc" libreoffice-calc "Office;Spreadsheet;"
fi

chown -R prime:prime "$DESKTOP_DIR"
chmod 0755 "$DESKTOP_DIR"/*.desktop

# PrimeBook Neo wallpaper and XFCE appearance helper are configured above.


apt-get clean
rm -rf /var/lib/apt/lists/*
echo
echo "Desktop apps, shortcuts, wallpaper and XFCE polish installed for user prime."
DEBIAN_SCRIPT

echo
echo "Desktop apps, GDebi diagnostics, ARM64 local .deb helper and Electron launch integration installed."
echo "OpenCode launcher is installed when /opt/OpenCode/ai.opencode exists; log: /home/prime/Downloads/opencode-desktop.log."
echo "Use primebook-install-deb /path/to/package.deb for future local ARM64 packages."
echo "Restart the desktop to refresh application menus and the panel layout."
