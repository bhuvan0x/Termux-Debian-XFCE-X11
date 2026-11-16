#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

MODE="${1:-install}"
if [[ "$MODE" != install && "$MODE" != --remove ]]; then
  echo "Usage: bash scripts/install-modernclock.sh [--remove]" >&2
  exit 2
fi

if ! command -v proot-distro >/dev/null 2>&1; then
  echo "proot-distro is required. Install the Debian environment first." >&2
  exit 1
fi

if [[ "$MODE" == "--remove" ]]; then
  echo "== Removing PrimeBook Modern Clock =="
  proot-distro login --isolated --user prime debian -- /bin/bash -lc '
    pkill -u "$(id -u)" -x conky 2>/dev/null || true
    rm -f "$HOME/.config/autostart/primebook-modernclock.desktop"
    rm -f "$HOME/.config/conky/primebook-modernclock.conf"
    echo "Clock configuration and autostart entry removed."
    echo "The conky-all package was left installed; remove it separately if no other app uses it."
  '
  exit 0
fi

echo "== Installing Conky for the XFCE Modern Clock =="
proot-distro login --isolated debian -- /bin/bash -lc '
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y conky-all fonts-noto-core
  command -v conky >/dev/null
'

echo "== Configuring the WhiteSur-compatible desktop clock =="
proot-distro login --isolated --user prime debian -- /bin/bash -s <<'DEBIAN_SCRIPT'
set -Eeuo pipefail

CONFIG_DIR="$HOME/.config/conky"
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$CONFIG_DIR" "$AUTOSTART_DIR"

cat > "$CONFIG_DIR/primebook-modernclock.conf" <<'CONKY_CONFIG'
conky.config = {
    alignment = 'top_right',
    background = false,
    border_width = 0,
    cpu_avg_samples = 2,
    default_color = 'F3F6FF',
    draw_borders = false,
    draw_graph_borders = false,
    draw_outline = false,
    draw_shades = false,
    double_buffer = true,
    gap_x = 64,
    gap_y = 104,
    maximum_width = 520,
    minimum_width = 320,
    own_window = true,
    own_window_class = 'PrimeBookModernClock',
    own_window_type = 'desktop',
    own_window_transparent = true,
    own_window_argb_visual = true,
    own_window_argb_value = 0,
    own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',
    update_interval = 1,
    use_xft = true,
    xftalpha = 1,
};

conky.text = [[
${font Noto Sans:style=Bold:size=13}${color #9BBEFF}${execi 60 date +%A | tr '[:lower:]' '[:upper:]'}${color}
${voffset 5}${font Noto Sans:style=Regular:size=15}${color #C9D8F5}${time %d %B %Y}${color}
${voffset 1}${font Noto Sans:style=Regular:size=54}${color #F3F6FF}${time %H:%M}${color}
]];
CONKY_CONFIG

cat > "$AUTOSTART_DIR/primebook-modernclock.desktop" <<'AUTOSTART'
[Desktop Entry]
Type=Application
Name=PrimeBook Modern Clock
Comment=Minimal WhiteSur-inspired desktop clock
Exec=conky --daemonize --config=/home/prime/.config/conky/primebook-modernclock.conf
OnlyShowIn=XFCE;
Terminal=false
StartupNotify=false
Hidden=false
X-GNOME-Autostart-enabled=true
AUTOSTART

chmod 0644 "$CONFIG_DIR/primebook-modernclock.conf" "$AUTOSTART_DIR/primebook-modernclock.desktop"

# Replace only this project's clock process; do not touch other Conky instances.
pkill -u "$(id -u)" -f 'conky.*primebook-modernclock.conf' 2>/dev/null || true
sleep 1
DISPLAY="${DISPLAY:-:0}" conky --daemonize --config="$CONFIG_DIR/primebook-modernclock.conf"

echo "Installed: top-right transparent clock (day, date, 24-hour time)."
echo "Autostart: $AUTOSTART_DIR/primebook-modernclock.desktop"
DEBIAN_SCRIPT

echo
echo "Modern Clock is installed. It appears on the desktop without changing XFCE panels or the dock."
echo "To remove it later: bash scripts/install-modernclock.sh --remove"
