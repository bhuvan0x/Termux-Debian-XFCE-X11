#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Lightweight XFCE performance profile for Debian PRoot + Termux:X11.
# Run from Termux while the prime XFCE desktop is running.

command -v proot-distro >/dev/null 2>&1 || {
  echo "proot-distro is missing. Run scripts/setup-termux.sh first." >&2
  exit 1
}
PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Update Termux proot-distro to version 5.8.0 or newer first." >&2
  exit 2
fi

ACTION="${1:-status}"
case "$ACTION" in
  status|fast|restore) ;;
  *)
    echo "Usage: bash scripts/performance.sh [status|fast|restore]" >&2
    exit 2
    ;;
esac

proot-distro login --isolated --shared-x11 --user prime debian -- /bin/bash -s -- "$ACTION" <<'DEBIAN_SCRIPT'
set -Eeuo pipefail
ACTION="${1:-status}"
export DISPLAY="${DISPLAY:-:0}"

SESSION_PID="$(pgrep -u "$(id -u)" -x xfce4-session | head -n 1 || true)"
DBUS_ADDRESS=""
if [ -n "$SESSION_PID" ] && [ -r "/proc/$SESSION_PID/environ" ]; then
  DBUS_ADDRESS="$(tr '\0' '\n' < "/proc/$SESSION_PID/environ" | sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p' | head -n 1)"
fi

if [ -z "$DBUS_ADDRESS" ]; then
  for bus_file in "$HOME"/.dbus/session-bus/*; do
    [ -f "$bus_file" ] || continue
    candidate="$(sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p' "$bus_file" | head -n 1 | sed 's/^"//; s/"$//')"
    [ -n "$candidate" ] || continue
    if DBUS_SESSION_BUS_ADDRESS="$candidate" xfconf-query -c xfwm4 -p /general/use_compositing >/dev/null 2>&1; then
      DBUS_ADDRESS="$candidate"
      break
    fi
  done
fi

if [ -z "$DBUS_ADDRESS" ]; then
  echo "ERROR: Could not locate the running XFCE session D-Bus."
  echo "Start the desktop with 'start-all', then rerun this command."
  exit 3
fi
export DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDRESS"

if ! xfconf-query -c xfwm4 -p /general/use_compositing >/dev/null 2>&1; then
  echo "ERROR: The discovered D-Bus address does not reach the live XFCE session."
  exit 4
fi

STATE_DIR="$HOME/.config/primebook"
STATE_FILE="$STATE_DIR/performance-original.conf"
mkdir -p "$STATE_DIR"

get_bool() {
  local channel="$1" property="$2" fallback="$3" value
  value="$(xfconf-query -c "$channel" -p "$property" 2>/dev/null || true)"
  case "$value" in true|false) printf '%s' "$value" ;; *) printf '%s' "$fallback" ;; esac
}
set_bool() {
  xfconf-query -c "$1" -p "$2" --create -t bool -s "$3" >/dev/null
}

case "$ACTION" in
  status)
    printf 'XFCE compositor: %s\n' "$(get_bool xfwm4 /general/use_compositing unknown)"
    printf 'GTK animations:  %s\n' "$(get_bool xsettings /Gtk/EnableAnimations unknown)"
    if [ -f "$STATE_FILE" ]; then
      echo "Saved original settings: available (restore supported)"
    else
      echo "Saved original settings: none"
    fi
    ;;
  fast)
    if [ ! -f "$STATE_FILE" ]; then
      old_compositor="$(get_bool xfwm4 /general/use_compositing true)"
      old_animations="$(get_bool xsettings /Gtk/EnableAnimations true)"
      printf 'compositor=%s\nanimations=%s\n' "$old_compositor" "$old_animations" > "$STATE_FILE"
      chmod 0600 "$STATE_FILE"
    fi
    set_bool xfwm4 /general/use_compositing false
    set_bool xsettings /Gtk/EnableAnimations false
    echo "FAST profile applied to the live XFCE session."
    echo "- XFCE compositing disabled to reduce rendering/compositing overhead."
    echo "- GTK animations disabled to reduce UI animation work."
    echo "- Wallpaper, Fresco, panel layout, themes, audio, printing and services were not changed."
    echo "Run 'bash scripts/performance.sh restore' to restore the settings captured before the first FAST run."
    ;;
  restore)
    if [ ! -f "$STATE_FILE" ]; then
      echo "No saved original profile exists; nothing was changed."
      exit 0
    fi
    old_compositor="$(sed -n 's/^compositor=//p' "$STATE_FILE" | head -n 1)"
    old_animations="$(sed -n 's/^animations=//p' "$STATE_FILE" | head -n 1)"
    case "$old_compositor:$old_animations" in
      true:true|true:false|false:true|false:false) ;;
      *) echo "Saved profile is invalid; refusing to apply it." >&2; exit 5 ;;
    esac
    set_bool xfwm4 /general/use_compositing "$old_compositor"
    set_bool xsettings /Gtk/EnableAnimations "$old_animations"
    rm -f "$STATE_FILE"
    echo "Restored the XFCE settings captured before the first FAST run."
    ;;
esac
DEBIAN_SCRIPT
