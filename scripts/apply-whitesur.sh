#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

command -v proot-distro >/dev/null 2>&1 || {
  echo "proot-distro is missing. Run scripts/setup-termux.sh first." >&2
  exit 1
}
PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Update Termux proot-distro to version 5.8.0 or newer first." >&2
  exit 2
fi

echo "== Installing the complete persistent WhiteSur + dock profile =="

proot-distro login --isolated --user prime debian -- /bin/bash -s <<'DEBIAN_SCRIPT'
set -Eeuo pipefail

THEME_ROOT="$HOME/.local/share/themes"
ICON_ROOT="$HOME/.local/share/icons"
WALL_ROOT="$HOME/.local/share/backgrounds"
CACHE_ROOT="$HOME/.cache/whitesur"
WALLPAPER="$WALL_ROOT/WhiteSur-wallpaper.png"
mkdir -p "$THEME_ROOT" "$ICON_ROOT" "$WALL_ROOT" "$CACHE_ROOT" "$HOME/.themes" "$HOME/.icons"

# Find the installed WhiteSur GTK/XFWM theme.
THEME_DIR=""
for candidate in "$THEME_ROOT"/WhiteSurPrime*; do
  [ -d "$candidate" ] || continue
  if [ -d "$candidate/gtk-3.0" ] && [ -d "$candidate/xfwm4" ]; then
    THEME_DIR="$candidate"
    break
  fi
done
if [ -z "$THEME_DIR" ]; then
  echo "ERROR: WhiteSurPrime GTK/XFWM assets are missing. Install the theme assets first." >&2
  exit 3
fi
GTK_THEME="$(basename "$THEME_DIR")"
[ -e "$HOME/.themes/$GTK_THEME" ] || ln -s "$THEME_DIR" "$HOME/.themes/$GTK_THEME"

# Ensure WhiteSur dark icons are installed.
ICON_SOURCE="/tmp/whitesur-review/WhiteSur-icon-theme"
if [ ! -d "$ICON_ROOT/WhiteSurPrime-dark" ]; then
  ICON_SOURCE="$CACHE_ROOT/WhiteSur-icon-theme"
  if [ ! -d "$ICON_SOURCE/.git" ]; then
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$ICON_SOURCE"
  fi
  bash "$ICON_SOURCE/install.sh" --dest "$ICON_ROOT" --name WhiteSurPrime
fi

# Ensure matching WhiteSur cursors are installed.
CURSOR_SOURCE="/tmp/whitesur-review/WhiteSur-cursors"
if [ ! -d "$ICON_ROOT/WhiteSur-cursors" ]; then
  CURSOR_SOURCE="$CACHE_ROOT/WhiteSur-cursors"
  if [ ! -d "$CURSOR_SOURCE/.git" ]; then
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-cursors.git "$CURSOR_SOURCE"
  fi
  if [ ! -d "$CURSOR_SOURCE/dist" ]; then
    (cd "$CURSOR_SOURCE" && bash build.sh)
  fi
  (cd "$CURSOR_SOURCE" && bash install.sh)
fi

for asset in "$ICON_ROOT"/WhiteSurPrime* "$ICON_ROOT/WhiteSur-cursors"; do
  [ -e "$asset" ] || continue
  target="$HOME/.icons/$(basename "$asset")"
  [ -e "$target" ] || ln -s "$asset" "$target"
done

# Install the matching WhiteSur wallpaper from the cached upstream source.
GTK_SOURCE="/tmp/whitesur-review/WhiteSur-gtk-theme"
if [ ! -f "$GTK_SOURCE/src/assets/gnome-shell/backgrounds/background-default.png" ]; then
  GTK_SOURCE="$CACHE_ROOT/WhiteSur-gtk-theme"
  if [ ! -d "$GTK_SOURCE/.git" ]; then
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$GTK_SOURCE"
  fi
fi
install -m 0644 "$GTK_SOURCE/src/assets/gnome-shell/backgrounds/background-default.png" "$WALLPAPER"

ICON_THEME="WhiteSurPrime-dark"
CURSOR_THEME="WhiteSur-cursors"
if [ -f "$ICON_ROOT/$ICON_THEME/index.theme" ] && command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "$ICON_ROOT/$ICON_THEME" >/dev/null 2>&1 || true
fi

# Configure persistent XFCE channel files. The values are written to the
# user's config directory; a login hook below reapplies them on the live bus.
dbus-run-session -- /bin/bash -s -- "$GTK_THEME" "$ICON_THEME" "$CURSOR_THEME" "$WALLPAPER" <<'XFCONF_SCRIPT'
set -Eeuo pipefail
GTK_THEME="$1"
ICON_THEME="$2"
CURSOR_THEME="$3"
WALLPAPER="$4"

set_string() { xfconf-query -c "$1" -p "$2" --create -t string -s "$3"; }
set_int() { xfconf-query -c "$1" -p "$2" --create -t int -s "$3"; }
set_bool() { xfconf-query -c "$1" -p "$2" --create -t bool -s "$3"; }

set_string xsettings /Net/ThemeName "$GTK_THEME"
set_string xfwm4 /general/theme "$GTK_THEME"
set_string xsettings /Net/IconThemeName "$ICON_THEME"
set_string xsettings /Gtk/CursorThemeName "$CURSOR_THEME"
set_string xsettings /Gtk/FontName 'Noto Sans 10'
set_string xfwm4 /general/title_font 'Noto Sans Bold 10'

mapfile -t BACKDROP_PROPS < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/last-image$' || true)
if [ "${#BACKDROP_PROPS[@]}" -eq 0 ]; then
  BACKDROP_PROPS=(/backdrop/screen0/monitor0/workspace0/last-image)
fi
for property in "${BACKDROP_PROPS[@]}"; do
  set_string xfce4-desktop "$property" "$WALLPAPER"
done

# Preserve existing panels and items; style the current auto-hidden panel.
mapfile -t PANEL_IDS < <(xfconf-query -c xfce4-panel -p /panels 2>/dev/null | grep -Eo '[0-9]+' | sort -nu)
DOCK_PANEL=""
for id in "${PANEL_IDS[@]}"; do
  behavior="$(xfconf-query -c xfce4-panel -p "/panels/panel-$id/autohide-behavior" 2>/dev/null || true)"
  if [ "$behavior" = "2" ]; then DOCK_PANEL="$id"; fi
done
if [ -z "$DOCK_PANEL" ] && [ "${#PANEL_IDS[@]}" -gt 0 ]; then
  DOCK_PANEL="${PANEL_IDS[$(("${#PANEL_IDS[@]}" - 1))]}"
fi
if [ -n "$DOCK_PANEL" ]; then
  DOCK="/panels/panel-$DOCK_PANEL"
  set_int xfce4-panel "$DOCK/length" 52
  set_bool xfce4-panel "$DOCK/length-adjust" false
  set_bool xfce4-panel "$DOCK/position-locked" true
  set_int xfce4-panel "$DOCK/size" 50
  set_int xfce4-panel "$DOCK/icon-size" 34
  set_int xfce4-panel "$DOCK/autohide-behavior" 2
  set_int xfce4-panel "$DOCK/enter-opacity" 100
  set_int xfce4-panel "$DOCK/leave-opacity" 92
  while IFS= read -r line; do
    plugin_path="${line%%:*}"
    plugin_type="${line#*: }"
    [[ "$plugin_path" =~ ^/plugins/plugin-([0-9]+)$ ]] || continue
    plugin_id="${BASH_REMATCH[1]}"
    if [ "$plugin_type" = "tasklist" ]; then
      set_bool xfce4-panel "/plugins/plugin-$plugin_id/show-labels" false
      set_bool xfce4-panel "/plugins/plugin-$plugin_id/flat-buttons" true
      set_bool xfce4-panel "/plugins/plugin-$plugin_id/show-tooltips" true
    fi
  done < <(xfconf-query -c xfce4-panel -lv 2>/dev/null || true)
fi
set_string xfce4-keyboard-shortcuts '/commands/custom/<Super>space' 'xfce4-appfinder --collapsed'
set_string xfce4-keyboard-shortcuts '/commands/custom/<Super>e' 'xfce4-appfinder --expanded'
XFCONF_SCRIPT

# XFCE autostart hook: reapply the full profile on every desktop login.
mkdir -p "$HOME/.config/autostart" "$HOME/.local/bin"
cat > "$HOME/.local/bin/primebook-whitesur-session.sh" <<'LOGIN_SCRIPT'
#!/bin/bash
set -eu
GTK_THEME="__GTK_THEME__"
ICON_THEME="WhiteSurPrime-dark"
CURSOR_THEME="WhiteSur-cursors"
WALLPAPER="$HOME/.local/share/backgrounds/WhiteSur-wallpaper.png"

for attempt in 1 2 3 4 5 6 7 8 9 10; do
  if xfconf-query -c xsettings -p /Net/ThemeName >/dev/null 2>&1; then
    set_value() { xfconf-query -c "$1" -p "$2" --create -t "$3" -s "$4"; }
    set_value xsettings /Net/ThemeName string "$GTK_THEME"
    set_value xfwm4 /general/theme string "$GTK_THEME"
    set_value xsettings /Net/IconThemeName string "$ICON_THEME"
    set_value xsettings /Gtk/CursorThemeName string "$CURSOR_THEME"
    set_value xsettings /Gtk/FontName string 'Noto Sans 10'
    set_value xfwm4 /general/title_font string 'Noto Sans Bold 10'
    while IFS= read -r property; do
      [ -n "$property" ] && set_value xfce4-desktop "$property" string "$WALLPAPER"
    done < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/last-image$' || true)

    mapfile -t PANEL_IDS < <(xfconf-query -c xfce4-panel -p /panels 2>/dev/null | grep -Eo '[0-9]+' | sort -nu)
    DOCK_PANEL=""
    for id in "${PANEL_IDS[@]}"; do
      behavior="$(xfconf-query -c xfce4-panel -p "/panels/panel-$id/autohide-behavior" 2>/dev/null || true)"
      if [ "$behavior" = "2" ]; then DOCK_PANEL="$id"; fi
    done
    if [ -z "$DOCK_PANEL" ] && [ "${#PANEL_IDS[@]}" -gt 0 ]; then
      DOCK_PANEL="${PANEL_IDS[$(("${#PANEL_IDS[@]}" - 1))]}"
    fi
    if [ -n "$DOCK_PANEL" ]; then
      DOCK="/panels/panel-$DOCK_PANEL"
      set_value xfce4-panel "$DOCK/length" int 52
      set_value xfce4-panel "$DOCK/length-adjust" bool false
      set_value xfce4-panel "$DOCK/position-locked" bool true
      set_value xfce4-panel "$DOCK/size" int 50
      set_value xfce4-panel "$DOCK/icon-size" int 34
      set_value xfce4-panel "$DOCK/autohide-behavior" int 2
      set_value xfce4-panel "$DOCK/enter-opacity" int 100
      set_value xfce4-panel "$DOCK/leave-opacity" int 92
      while IFS= read -r line; do
        plugin_path="${line%%:*}"
        plugin_type="${line#*: }"
        [[ "$plugin_path" =~ ^/plugins/plugin-([0-9]+)$ ]] || continue
        plugin_id="${BASH_REMATCH[1]}"
        if [ "$plugin_type" = "tasklist" ]; then
          set_value xfce4-panel "/plugins/plugin-$plugin_id/show-labels" bool false
          set_value xfce4-panel "/plugins/plugin-$plugin_id/flat-buttons" bool true
          set_value xfce4-panel "/plugins/plugin-$plugin_id/show-tooltips" bool true
        fi
      done < <(xfconf-query -c xfce4-panel -lv 2>/dev/null || true)
    fi
    set_value xfce4-keyboard-shortcuts '/commands/custom/<Super>space' string 'xfce4-appfinder --collapsed'
    set_value xfce4-keyboard-shortcuts '/commands/custom/<Super>e' string 'xfce4-appfinder --expanded'
    xfce4-panel -r >/dev/null 2>&1 || true
    exit 0
  fi
  sleep 2
done
exit 0
LOGIN_SCRIPT
sed -i "s|__GTK_THEME__|$GTK_THEME|g" "$HOME/.local/bin/primebook-whitesur-session.sh"
chmod 0755 "$HOME/.local/bin/primebook-whitesur-session.sh"

cat > "$HOME/.config/autostart/primebook-whitesur.desktop" <<'AUTOSTART_ENTRY'
[Desktop Entry]
Type=Application
Name=PrimeBook WhiteSur Appearance
Comment=Restore WhiteSur theme, icons, cursor, wallpaper and dock on login
Exec=/home/prime/.local/bin/primebook-whitesur-session.sh
OnlyShowIn=XFCE;
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
AUTOSTART_ENTRY

# GTK fallback for applications launched before xfsettingsd completes startup.
mkdir -p "$HOME/.config/gtk-3.0"
GTK_SETTINGS="$HOME/.config/gtk-3.0/settings.ini"
touch "$GTK_SETTINGS"
if ! grep -q '^\[Settings\]$' "$GTK_SETTINGS"; then
  tmp_settings="$(mktemp)"
  printf '%s\n' '[Settings]' > "$tmp_settings"
  cat "$GTK_SETTINGS" >> "$tmp_settings"
  mv "$tmp_settings" "$GTK_SETTINGS"
fi
for entry in "gtk-theme-name=$GTK_THEME" "gtk-icon-theme-name=$ICON_THEME" "gtk-cursor-theme-name=$CURSOR_THEME" "gtk-font-name=Noto Sans 10"; do
  key="${entry%%=*}"
  if grep -q "^$key=" "$GTK_SETTINGS"; then
    sed -i "s|^$key=.*|$entry|" "$GTK_SETTINGS"
  else
    echo "$entry" >> "$GTK_SETTINGS"
  fi
done

echo "WhiteSur theme: $GTK_THEME"
echo "Icons: $ICON_THEME | Cursor: $CURSOR_THEME | Font: Noto Sans 10"
echo "Persistent login hook installed."
DEBIAN_SCRIPT

echo
echo "== Restarting the existing desktop once to activate the profile =="
bash "$SCRIPT_DIR/stop-all.sh" || true
sleep 2
exec bash "$SCRIPT_DIR/start-all.sh"
