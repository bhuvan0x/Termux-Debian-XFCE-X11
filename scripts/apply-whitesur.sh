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

# XFCE appearance is applied by the autostart hook on the real session bus.

# XFCE autostart hook: reapply the full profile on every desktop login.
mkdir -p "$HOME/.config/autostart" "$HOME/.local/bin"
cat > "$HOME/.local/bin/primebook-whitesur-session.sh" <<'LOGIN_SCRIPT'
#!/bin/bash
set -u
GTK_THEME="__GTK_THEME__"
ICON_THEME="WhiteSurPrime-dark"
CURSOR_THEME="WhiteSur-cursors"
WALLPAPER="$HOME/.local/share/backgrounds/WhiteSur-wallpaper.png"
LOG="$HOME/.cache/primebook-whitesur-session.log"
mkdir -p "$(dirname "$LOG")"
exec >>"$LOG" 2>&1
echo "[$(date -Is)] WhiteSur login hook started; waiting for XFCE session restoration."

for attempt in $(seq 1 30); do
  if xfconf-query -c xsettings -p /Net/ThemeName >/dev/null 2>&1; then break; fi
  sleep 1
done
# XFCE may restore cached settings after the settings daemon first appears.
sleep 12

set_value() { xfconf-query -c "$1" -p "$2" --create -t "$3" -s "$4"; }
apply_profile() {
  set_value xsettings /Net/ThemeName string "$GTK_THEME"
  set_value xfwm4 /general/theme string "$GTK_THEME"
  set_value xsettings /Net/IconThemeName string "$ICON_THEME"
  set_value xsettings /Gtk/CursorThemeName string "$CURSOR_THEME"
  set_value xsettings /Gtk/FontName string 'Noto Sans 10'
  set_value xfwm4 /general/title_font string 'Noto Sans Bold 10'
  while IFS= read -r property; do
    [ -n "$property" ] && set_value xfce4-desktop "$property" string "$WALLPAPER"
  done < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/last-image$' || true)

  mapfile -t PANEL_IDS < <(xfconf-query -c xfce4-panel -p /panels 2>/dev/null | sed -nE '/^[[:space:]]*[0-9]+[[:space:]]*$/s/^[[:space:]]*([0-9]+)[[:space:]]*$/\1/p' | sort -nu)
  DOCK_PANEL=""
  for id in "${PANEL_IDS[@]}"; do
    behavior="$(xfconf-query -c xfce4-panel -p "/panels/panel-$id/autohide-behavior" 2>/dev/null || true)"
    if [ "$behavior" = "2" ]; then DOCK_PANEL="$id"; fi
  done
  if [ -z "$DOCK_PANEL" ] && [ "${#PANEL_IDS[@]}" -gt 0 ]; then
    DOCK_PANEL="${PANEL_IDS[$(("${#PANEL_IDS[@]}" - 1))]}"
  fi
  if [ -n "$DOCK_PANEL" ]; then
    # Center the contiguous application-icon group with transparent expanders.
    # Preserve all existing plugin IDs and their relative order.
    PANEL_PATH="/panels/panel-$DOCK_PANEL"
    mapfile -t ORDER < <(xfconf-query -c xfce4-panel -p "$PANEL_PATH/plugin-ids" 2>/dev/null | sed -nE '/^[[:space:]]*[0-9]+[[:space:]]*$/s/^[[:space:]]*([0-9]+)[[:space:]]*$/\1/p' || true)
    APP_POS=()
    for i in "${!ORDER[@]}"; do
      kind="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-${ORDER[$i]}" 2>/dev/null || true)"
      case "$kind" in launcher|tasklist|docklike) APP_POS+=("$i");; esac
    done
    if [ "${#APP_POS[@]}" -gt 0 ]; then
      FIRST="${APP_POS[0]}"
      LAST="${APP_POS[$(("${#APP_POS[@]}" - 1))]}"
      BEFORE="${ORDER[$((FIRST-1))]:-}"
      AFTER="${ORDER[$((LAST+1))]:-}"
      BEFORE_EXPAND=false; AFTER_EXPAND=false
      if [ -n "$BEFORE" ] && [ "$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$BEFORE" 2>/dev/null || true)" = separator ] && [ "$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$BEFORE/expand" 2>/dev/null || true)" = true ]; then BEFORE_EXPAND=true; fi
      if [ -n "$AFTER" ] && [ "$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$AFTER" 2>/dev/null || true)" = separator ] && [ "$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$AFTER/expand" 2>/dev/null || true)" = true ]; then AFTER_EXPAND=true; fi
      if [ "$BEFORE_EXPAND" != true ] || [ "$AFTER_EXPAND" != true ]; then
        mapfile -t ALL_PLUGIN_IDS < <(xfconf-query -c xfce4-panel -l 2>/dev/null | grep -Eo '^/plugins/plugin-[0-9]+$' | grep -Eo '[0-9]+' | sort -nu)
        MAX_PLUGIN=0
        for n in "${ALL_PLUGIN_IDS[@]}"; do if [ "$n" -gt "$MAX_PLUGIN" ]; then MAX_PLUGIN="$n"; fi; done
        NEW_BEFORE=$((MAX_PLUGIN+1)); NEW_AFTER=$((MAX_PLUGIN+2))
        for n in "$NEW_BEFORE" "$NEW_AFTER"; do
          xfconf-query -c xfce4-panel -p "/plugins/plugin-$n" --create -t string -s separator
          xfconf-query -c xfce4-panel -p "/plugins/plugin-$n/expand" --create -t bool -s true
          xfconf-query -c xfce4-panel -p "/plugins/plugin-$n/style" --create -t uint -s 0
        done
        NEW_ORDER=()
        for i in "${!ORDER[@]}"; do
          [ "$i" -eq "$FIRST" ] && NEW_ORDER+=("$NEW_BEFORE")
          NEW_ORDER+=("${ORDER[$i]}")
          [ "$i" -eq "$LAST" ] && NEW_ORDER+=("$NEW_AFTER")
        done
        ARRAY_ARGS=(xfconf-query -c xfce4-panel -p "$PANEL_PATH/plugin-ids" --force-array)
        for n in "${NEW_ORDER[@]}"; do ARRAY_ARGS+=(-t int -s "$n"); done
        "${ARRAY_ARGS[@]}"
      fi
    fi
    DOCK="/panels/panel-$DOCK_PANEL"
    set_value xfce4-panel "$DOCK/length" int 52
    set_value xfce4-panel "$DOCK/length-adjust" bool false
    set_value xfce4-panel "$DOCK/position-locked" bool true
    set_value xfce4-panel "$DOCK/position" string "p=10;x=0;y=0"
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
}
apply_profile
sleep 5
apply_profile
xfce4-panel -r >/dev/null 2>&1 || true
echo "[$(date -Is)] WhiteSur theme=$GTK_THEME icons=$ICON_THEME cursor=$CURSOR_THEME; dock profile enforced."
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
X-XFCE-Autostart-Phase=Application
StartupNotify=false
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
AUTOSTART_ENTRY

# Liquid-glass-inspired dock surface: translucent dark glass, a fine rim and rounded corners.
mkdir -p "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-3.0/gtk.css" <<'GLASS_CSS'
#XfcePanelWindow {
  background-color: rgba(20, 24, 38, 0.76);
  border: 1px solid rgba(235, 242, 255, 0.28);
  border-radius: 18px;
  background-clip: padding-box;
}
#XfcePanelWindow button,
#XfcePanelWindow .tasklist button {
  border-radius: 12px;
  background-clip: padding-box;
}
#XfcePanelWindow button:hover,
#XfcePanelWindow .tasklist button:hover {
  background-color: rgba(210, 225, 255, 0.16);
}
GLASS_CSS

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
