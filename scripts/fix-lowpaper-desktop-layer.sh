#!/usr/bin/env bash
# Patch lowpaper 0.1.1 so XFCE's desktop/icons are reliably kept above the video.
# Run as the prime desktop user. The active XFCE session must be available on DISPLAY.
set -Eeuo pipefail

LOWPAPER="${HOME}/.local/bin/lowpaper"
[ -x "$LOWPAPER" ] || { echo "lowpaper not found at $LOWPAPER" >&2; exit 1; }
[ -n "${DISPLAY:-}" ] || { echo "DISPLAY is empty; run this from the Debian XFCE session." >&2; exit 1; }
command -v xfconf-query >/dev/null 2>&1 || { echo "xfconf-query is missing." >&2; exit 1; }
[ "$(xfconf-query -c xfwm4 -p /general/use_compositing 2>/dev/null || true)" = true ] || {
  echo "XFCE compositing is disabled. Enable it in Window Manager Tweaks > Compositor, then retry." >&2
  exit 1
}

# Reconnect to the actual XFCE session bus. PRoot sessions can have a different
# or empty DBUS_SESSION_BUS_ADDRESS even while sharing the X11 display.
DBUS_BUS=""
if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] && xfconf-query -c xfwm4 -p /general/use_compositing >/dev/null 2>&1; then
  DBUS_BUS="$DBUS_SESSION_BUS_ADDRESS"
else
  for bus_socket in /tmp/dbus-*; do
    [ -S "$bus_socket" ] || continue
    candidate="unix:path=$bus_socket"
    if DBUS_SESSION_BUS_ADDRESS="$candidate" xfconf-query -c xfwm4 -p /general/use_compositing >/dev/null 2>&1; then
      DBUS_BUS="$candidate"
      break
    fi
  done
fi
[ -n "$DBUS_BUS" ] || { echo "Cannot connect to the active XFCE session D-Bus; open the XFCE desktop and retry." >&2; exit 1; }
export DBUS_SESSION_BUS_ADDRESS="$DBUS_BUS"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$LOWPAPER.before-xfce-layer-fix-$STAMP"
cp -p "$LOWPAPER" "$BACKUP"

python3 - "$LOWPAPER" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
if "LOWPAPER_XFCE_LAYER_FIX=1" in text:
    print("The XFCE desktop-layer fix is already installed.")
    raise SystemExit(0)
if "VERSION=0.1.1" not in text or "icons_shim() {" not in text or "xfdesktop_over() {" not in text:
    raise SystemExit("Unsupported lowpaper version/layout; no changes made.")

start = text.index("icons_shim() {")
end = text.index("backdrop_clear() {", start)
icons = r'''# Keep this path independent of pgrep: an isolated PRoot process table cannot
# see xfdesktop when lowpaper is launched from another PRoot login.
icons_shim() {
  local so=${XDG_CACHE_HOME:-$HOME/.cache}/lowpaper/rgba.so
  [ "$ICONS" = 1 ] && xfce && have xfdesktop || return 1
  [ "$(xfconf-query -c xfwm4 -p /general/use_compositing 2>/dev/null)" = true ] || return 1
  [ -s "$so" ] || {
    have gcc || return 1
    mkdir -p "${so%/*}" || return 1
    gcc -shared -fPIC -O2 -o "$so" -x c - -ldl <<'C' || return 1
#define _GNU_SOURCE
#include <dlfcn.h>
void *gdk_screen_get_rgba_visual(void *);
void *gdk_screen_get_system_visual(void *s) {
    static void *(*real)(void *);
    void *v = gdk_screen_get_rgba_visual(s);
    if (v) return v;
    if (!real) real = (void *(*)(void *))dlsym(RTLD_NEXT, "gdk_screen_get_system_visual");
    return real(s);
}
C
  }
  [ -s "$so" ] || return 1
  echo "$so"
}
'''
text = text[:start] + icons + text[end:]

start = text.index("xfdesktop_over() {")
end = text.index("# ---------- Wayland ----------", start)
over = r'''# Restart xfdesktop with the RGBA shim. Do not use pgrep or /proc maps here:
# PRoot's isolated process view can hide the existing desktop process.
xfdesktop_over() {
  local so="$1"
  xfdesktop --quit >/dev/null 2>&1 || true
  for _ in $(seq 30); do
    has_desktop || break
    sleep 0.1
  done
  if has_desktop; then
    echo "lowpaper: xfdesktop did not release its old desktop window; refusing to leave the video over the icons." >&2
    return 1
  fi
  LD_PRELOAD="$so" setsid xfdesktop </dev/null >/dev/null 2>&1 9>&- &
  for _ in $(seq 40); do
    has_desktop && return 0
    sleep 0.1
  done
  echo "lowpaper: xfdesktop did not recreate its desktop window with the RGBA shim." >&2
  return 1
}

'''
text = text[:start] + over + text[end:]

old = '    [ -n "$so" ] && xfdesktop_over "$so" $new'
new = '''    if [ -n "$so" ]; then
      if ! xfdesktop_over "$so" "$new"; then\n      stop\n      die "could not put XFCE icons above the wallpaper; wallpaper was stopped to prevent an overlay."\n    fi
    else
      stop\n      die "could not prepare the XFCE RGBA desktop layer; wallpaper was stopped to prevent an overlay."
    fi'''
if text.count(old) != 1:
    raise SystemExit("Could not locate the expected XFCE layer activation line; no changes made.")
text = text.replace(old, new, 1)

# Scan the complete EWMH stacking list; xfdesktop is not guaranteed to be among
# the first three windows on every XFCE session.
old = '''has_desktop() {  # a file manager owns a desktop window (xfdesktop, caja, nemo...)
  local w
  for w in $(xprop -root _NET_CLIENT_LIST_STACKING 2>/dev/null | sed 's/.*#//; s/,/ /g' | awk '{for(i=1;i<=NF&&i<=3;i++)print $i}'); do
    xprop -id "$w" _NET_WM_WINDOW_TYPE 2>/dev/null | grep -q _DESKTOP && return
  done
  return 1
}'''
new = '''has_desktop() {  # a file manager owns a desktop window (xfdesktop, caja, nemo...)
  local w windows
  windows=$(xprop -root _NET_CLIENT_LIST_STACKING 2>/dev/null | sed 's/.*#//; s/,/ /g')
  for w in $windows; do
    xprop -id "$w" _NET_WM_WINDOW_TYPE 2>/dev/null | grep -q _DESKTOP && return 0
  done
  return 1
}'''
if text.count(old) != 1:
    raise SystemExit("Could not locate the expected desktop-window detector; no changes made.")
text = text.replace(old, new, 1)
text = text.replace("VERSION=0.1.1", "VERSION=0.1.1\n# LOWPAPER_XFCE_LAYER_FIX=1", 1)

path.write_text(text, encoding="utf-8")
PY

bash -n "$LOWPAPER"
grep -q 'LOWPAPER_XFCE_LAYER_FIX=1' "$LOWPAPER"
echo "Patched lowpaper XFCE layering."
echo "Backup: $BACKUP"
echo "Reapplying the current wallpaper through the corrected XFCE desktop layer..."
"$LOWPAPER" restore
echo "XFCE wallpaper layer reapplied. Check that desktop icons are visible and clickable."
