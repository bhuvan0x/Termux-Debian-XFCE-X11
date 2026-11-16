#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

command -v proot-distro >/dev/null 2>&1 || {
  echo "proot-distro is missing. Run scripts/setup-termux.sh first." >&2
  exit 1
}

PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Update Termux proot-distro to version 5.8.0 or newer first." >&2
  exit 2
fi

echo "== Applying WhiteSur Dark / Blue to the Debian XFCE desktop =="

proot-distro login --isolated --user prime debian -- /bin/bash -s <<'DEBIAN_SCRIPT'
set -Eeuo pipefail

THEME_ROOT="$HOME/.local/share/themes"
ICON_ROOT="$HOME/.local/share/icons"
WALL_ROOT="$HOME/.local/share/backgrounds"
CACHE_ROOT="$HOME/.cache/whitesur"
WALLPAPER="$WALL_ROOT/WhiteSur-wallpaper.png"

mkdir -p "$THEME_ROOT" "$ICON_ROOT" "$WALL_ROOT" "$CACHE_ROOT"

# Resolve the actual generated theme directory instead of assuming its name.
THEME_DIR=""
for candidate in "$THEME_ROOT"/WhiteSurPrime*; do
  [ -d "$candidate" ] || continue
  if [ -d "$candidate/gtk-3.0" ] && [ -d "$candidate/xfwm4" ]; then
    THEME_DIR="$candidate"
    break
  fi
done

if [ -z "$THEME_DIR" ]; then
  echo "ERROR: WhiteSurPrime GTK/XFWM theme assets were not found."
  echo "Available theme directories:"
  find "$THEME_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' 2>/dev/null || true
  exit 3
fi

# GTK and XFCE commonly search ~/.themes and ~/.icons first. Expose the
# installed theme through those standard paths without duplicating assets.
GTK_THEME="$(basename "$THEME_DIR")"
mkdir -p "$HOME/.themes" "$HOME/.icons"
if [ ! -e "$HOME/.themes/$GTK_THEME" ]; then
  ln -s "$THEME_DIR" "$HOME/.themes/$GTK_THEME"
fi

# Repair missing icon assets only; do not overwrite an existing icon theme.
ICON_SOURCE="/tmp/whitesur-review/WhiteSur-icon-theme"
if [ ! -d "$ICON_ROOT/WhiteSurPrime-dark" ]; then
  if [ ! -d "$ICON_SOURCE/.git" ]; then
    ICON_SOURCE="$CACHE_ROOT/WhiteSur-icon-theme"
    if [ ! -d "$ICON_SOURCE/.git" ]; then
      git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$ICON_SOURCE"
    fi
  fi
  bash "$ICON_SOURCE/install.sh" --dest "$ICON_ROOT" --name WhiteSurPrime
fi

# Repair missing cursor assets only; build from the upstream SVG sources.
CURSOR_SOURCE="/tmp/whitesur-review/WhiteSur-cursors"
if [ ! -d "$ICON_ROOT/WhiteSur-cursors" ]; then
  if [ ! -d "$CURSOR_SOURCE/.git" ]; then
    CURSOR_SOURCE="$CACHE_ROOT/WhiteSur-cursors"
    if [ ! -d "$CURSOR_SOURCE/.git" ]; then
      git clone --depth 1 https://github.com/vinceliuice/WhiteSur-cursors.git "$CURSOR_SOURCE"
    fi
  fi
  if [ ! -d "$CURSOR_SOURCE/dist" ]; then
    (cd "$CURSOR_SOURCE" && bash build.sh)
  fi
  (cd "$CURSOR_SOURCE" && bash install.sh)
fi

# Make icon and cursor themes discoverable through the standard ~/.icons path.
for asset in "$ICON_ROOT"/WhiteSurPrime* "$ICON_ROOT/WhiteSur-cursors"; do
  [ -e "$asset" ] || continue
  target="$HOME/.icons/$(basename "$asset")"
  [ -e "$target" ] || ln -s "$asset" "$target"
done

# Keep the wallpaper available even if the temporary review directory is cleared.
GTK_SOURCE="/tmp/whitesur-review/WhiteSur-gtk-theme"
if [ ! -f "$GTK_SOURCE/src/assets/gnome-shell/backgrounds/background-default.png" ]; then
  GTK_SOURCE="$CACHE_ROOT/WhiteSur-gtk-theme"
  if [ ! -d "$GTK_SOURCE/.git" ]; then
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$GTK_SOURCE"
  fi
fi

install -m 0644 \
  "$GTK_SOURCE/src/assets/gnome-shell/backgrounds/background-default.png" \
  "$WALLPAPER"

GTK_THEME="$(basename "$THEME_DIR")"
ICON_THEME="WhiteSurPrime-dark"
CURSOR_THEME="WhiteSur-cursors"

echo "GTK/XFWM theme: $GTK_THEME"
echo "Icon theme:     $ICON_THEME"
echo "Cursor theme:   $CURSOR_THEME"
echo "Wallpaper:      $WALLPAPER"

# A private D-Bus session makes xfconf-query write the user's persistent
# XFCE channel files. The desktop is restarted by the Termux wrapper below,
# so the live session starts with these settings on its normal session bus.
dbus-run-session -- /bin/bash -s -- "$GTK_THEME" "$ICON_THEME" "$CURSOR_THEME" "$WALLPAPER" <<'XFCONF_SCRIPT'
set -Eeuo pipefail

GTK_THEME="$1"
ICON_THEME="$2"
CURSOR_THEME="$3"
WALLPAPER="$4"

xfconf-query -c xsettings -p /Net/ThemeName --create -t string -s "$GTK_THEME"
xfconf-query -c xfwm4 -p /general/theme --create -t string -s "$GTK_THEME"
xfconf-query -c xsettings -p /Net/IconThemeName --create -t string -s "$ICON_THEME"
xfconf-query -c xsettings -p /Gtk/CursorThemeName --create -t string -s "$CURSOR_THEME"

mapfile -t BACKDROP_PROPS < <(
  xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/last-image$' || true
)

if [ "${#BACKDROP_PROPS[@]}" -eq 0 ]; then
  BACKDROP_PROPS=(/backdrop/screen0/monitor0/workspace0/last-image)
fi

for property in "${BACKDROP_PROPS[@]}"; do
  xfconf-query -c xfce4-desktop -p "$property" --create -t string -s "$WALLPAPER"
done

echo
echo "Saved XFCE settings:"
xfconf-query -c xsettings -p /Net/ThemeName
xfconf-query -c xfwm4 -p /general/theme
xfconf-query -c xsettings -p /Net/IconThemeName
xfconf-query -c xsettings -p /Gtk/CursorThemeName
XFCONF_SCRIPT


# Install a login-time enforcement hook. XFCE executes it on every login.
AUTOSTART_DIR="$HOME/.config/autostart"
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$AUTOSTART_DIR" "$LOCAL_BIN"

cat > "$LOCAL_BIN/primebook-whitesur-session.sh" <<'LOGIN_SCRIPT'
#!/bin/bash
set -eu
GTK_THEME="__GTK_THEME__"
ICON_THEME="WhiteSurPrime-dark"
CURSOR_THEME="WhiteSur-cursors"
WALLPAPER="$HOME/.local/share/backgrounds/WhiteSur-wallpaper.png"

# XFCE autostart inherits the active session D-Bus.
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  if xfconf-query -c xsettings -p /Net/ThemeName >/dev/null 2>&1; then
    xfconf-query -c xsettings -p /Net/ThemeName --create -t string -s "$GTK_THEME"
    xfconf-query -c xfwm4 -p /general/theme --create -t string -s "$GTK_THEME"
    xfconf-query -c xsettings -p /Net/IconThemeName --create -t string -s "$ICON_THEME"
    xfconf-query -c xsettings -p /Gtk/CursorThemeName --create -t string -s "$CURSOR_THEME"
    while IFS= read -r property; do
      [ -n "$property" ] || continue
      xfconf-query -c xfce4-desktop -p "$property" --create -t string -s "$WALLPAPER"
    done < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep '/last-image$' || true)
    exit 0
  fi
  sleep 2
done
exit 0
LOGIN_SCRIPT

sed -i "s|__GTK_THEME__|$GTK_THEME|g" "$LOCAL_BIN/primebook-whitesur-session.sh"
chmod 0755 "$LOCAL_BIN/primebook-whitesur-session.sh"

cat > "$AUTOSTART_DIR/primebook-whitesur.desktop" <<'AUTOSTART_ENTRY'
[Desktop Entry]
Type=Application
Name=PrimeBook WhiteSur Appearance
Comment=Restore WhiteSur appearance on every XFCE login
Exec=/bin/bash -lc "$HOME/.local/bin/primebook-whitesur-session.sh"
OnlyShowIn=XFCE;
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
AUTOSTART_ENTRY

# GTK fallback for apps started before xfsettingsd completes startup.
mkdir -p "$HOME/.config/gtk-3.0"
GTK_SETTINGS="$HOME/.config/gtk-3.0/settings.ini"
touch "$GTK_SETTINGS"
if ! grep -q '^\[Settings\]$' "$GTK_SETTINGS"; then
  echo "[Settings]" >> "$GTK_SETTINGS"
fi
for entry in "gtk-theme-name=$GTK_THEME" "gtk-icon-theme-name=$ICON_THEME" "gtk-cursor-theme-name=$CURSOR_THEME"; do
  key="${entry%%=*}"
  if grep -q "^$key=" "$GTK_SETTINGS"; then
    sed -i "s|^$key=.*|$entry|" "$GTK_SETTINGS"
  else
    echo "$entry" >> "$GTK_SETTINGS"
  fi
done

echo "Persistent WhiteSur login hook: $AUTOSTART_DIR/primebook-whitesur.desktop"
echo "GTK fallback settings: $GTK_SETTINGS"

echo "WhiteSur assets and persistent XFCE settings are ready."
DEBIAN_SCRIPT

echo
echo "== Restarting the existing XFCE / Termux:X11 session =="
bash "$SCRIPT_DIR/stop-all.sh" || true
sleep 2
echo "Starting the desktop with the new WhiteSur profile..."
exec bash "$SCRIPT_DIR/start-all.sh"
