#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Reversible macOS-inspired XFCE top menu bar for the PrimeBook Debian session.
# Run from Termux: bash scripts/macos-topbar.sh apply|status|rollback

ACTION="${1:-}"
case "$ACTION" in
  apply|status|rollback) ;;
  *) echo "Usage: bash scripts/macos-topbar.sh {apply|status|rollback}" >&2; exit 2 ;;
esac

command -v proot-distro >/dev/null 2>&1 || {
  echo "proot-distro is missing. Run scripts/setup-termux.sh first." >&2
  exit 1
}
PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Update Termux proot-distro to version 5.8.0 or newer first." >&2
  exit 2
fi

proot-distro login --isolated --shared-x11 --user prime debian -- /bin/bash -s -- "$ACTION" <<'DEBIAN_SCRIPT'
set -Eeuo pipefail
ACTION="$1"
export DISPLAY="${DISPLAY:-:0}"

STATE_DIR="$HOME/.config/primebook"
BACKUP_DIR="$STATE_DIR/backups"
STATE_FILE="$STATE_DIR/macos-topbar-state"
PANEL_XML="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
BACKUP_XML="$BACKUP_DIR/xfce4-panel-before-macos-topbar.xml"
mkdir -p "$BACKUP_DIR"

find_session_bus() {
  local pid address
  for pid in $(pgrep -x xfce4-session 2>/dev/null || true); do
    [ -r "/proc/$pid/environ" ] || continue
    address="$(tr '\0' '\n' < "/proc/$pid/environ" | sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p' | head -n 1)"
    [ -n "$address" ] || continue
    if DBUS_SESSION_BUS_ADDRESS="$address" xfconf-query -c xfce4-panel -p /panels >/dev/null 2>&1; then
      export DBUS_SESSION_BUS_ADDRESS="$address"
      return 0
    fi
  done
  return 1
}

read_array() {
  xfconf-query -c xfce4-panel -p "$1" 2>/dev/null |
    sed -nE '/^[[:space:]]*[0-9]+[[:space:]]*$/s/^[[:space:]]*([0-9]+)[[:space:]]*$/\1/p'
}

set_value() {
  xfconf-query -c xfce4-panel -p "$1" -s "$2"
}

if ! find_session_bus; then
  echo "ERROR: No live XFCE session D-Bus was found."
  echo "Start the desktop with start-all, then rerun this command."
  exit 3
fi

case "$ACTION" in
  status)
    echo "===== macOS TOP BAR ====="
    echo "Position: $(xfconf-query -c xfce4-panel -p /panels/panel-1/position 2>/dev/null || echo unavailable)"
    echo "Length: $(xfconf-query -c xfce4-panel -p /panels/panel-1/length 2>/dev/null || echo unavailable)%"
    echo "Size: $(xfconf-query -c xfce4-panel -p /panels/panel-1/size 2>/dev/null || echo unavailable) px"
    echo "Plugins:"
    xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null || true
    echo "Saved rollback state: $([ -f "$STATE_FILE" ] && echo yes || echo no)"
    echo "Plank: $(pgrep -x plank >/dev/null 2>&1 && echo running || echo not-running)"
    ;;

  apply)
    [ -e "$HOME/.config/primebook/plank-enabled" ] || {
      echo "ERROR: Plank migration marker is missing."
      echo "Enable Plank first with: bash scripts/plank-dock.sh install"
      exit 4
    }

    mapfile -t ACTIVE_PANELS < <(read_array /panels)
    if [[ ! " ${ACTIVE_PANELS[*]} " == *" 1 "* ]]; then
      echo "ERROR: XFCE panel 1 is not active. Refusing to guess which panel to modify."
      exit 5
    fi

    PANEL_PATH="/panels/panel-1"
    mapfile -t PLUGINS < <(read_array "$PANEL_PATH/plugin-ids")
    if [ "${#PLUGINS[@]}" -eq 0 ]; then
      echo "ERROR: Panel 1 has no readable plugin list. No changes made."
      exit 6
    fi

    # Require an existing separator so the menu stays left and status items
    # stay right. Do not replace or recreate any user plugins.
    EXPAND_SEPARATOR=""
    for id in "${PLUGINS[@]}"; do
      kind="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$id" 2>/dev/null || true)"
      if [ "$kind" = "separator" ]; then
        EXPAND_SEPARATOR="$id"
        break
      fi
    done
    if [ -z "$EXPAND_SEPARATOR" ]; then
      echo "ERROR: No separator plugin exists on panel 1."
      echo "No changes made. Add a Separator in Panel Preferences and retry."
      exit 7
    fi

    if [ ! -f "$STATE_FILE" ]; then
      [ -f "$PANEL_XML" ] && cp -a "$PANEL_XML" "$BACKUP_XML"
      ORIG_POSITION="$(xfconf-query -c xfce4-panel -p "$PANEL_PATH/position")"
      ORIG_LENGTH="$(xfconf-query -c xfce4-panel -p "$PANEL_PATH/length")"
      ORIG_LENGTH_ADJUST="$(xfconf-query -c xfce4-panel -p "$PANEL_PATH/length-adjust" 2>/dev/null || echo false)"
      ORIG_SIZE="$(xfconf-query -c xfce4-panel -p "$PANEL_PATH/size")"
      ORIG_ICON_SIZE="$(xfconf-query -c xfce4-panel -p "$PANEL_PATH/icon-size" 2>/dev/null || echo 0)"
      ORIG_AUTOHIDE="$(xfconf-query -c xfce4-panel -p "$PANEL_PATH/autohide-behavior" 2>/dev/null || echo 0)"
      ORIG_ENTER_OPACITY="$(xfconf-query -c xfce4-panel -p "$PANEL_PATH/enter-opacity" 2>/dev/null || echo 100)"
      ORIG_LEAVE_OPACITY="$(xfconf-query -c xfce4-panel -p "$PANEL_PATH/leave-opacity" 2>/dev/null || echo 100)"
      ORIG_POSITION_LOCKED="$(xfconf-query -c xfce4-panel -p "$PANEL_PATH/position-locked" 2>/dev/null || echo true)"
      {
        printf 'ORIG_POSITION=%q\n' "$ORIG_POSITION"
        printf 'ORIG_LENGTH=%q\n' "$ORIG_LENGTH"
        printf 'ORIG_LENGTH_ADJUST=%q\n' "$ORIG_LENGTH_ADJUST"
        printf 'ORIG_SIZE=%q\n' "$ORIG_SIZE"
        printf 'ORIG_ICON_SIZE=%q\n' "$ORIG_ICON_SIZE"
        printf 'ORIG_AUTOHIDE=%q\n' "$ORIG_AUTOHIDE"
        printf 'ORIG_ENTER_OPACITY=%q\n' "$ORIG_ENTER_OPACITY"
        printf 'ORIG_LEAVE_OPACITY=%q\n' "$ORIG_LEAVE_OPACITY"
        printf 'ORIG_POSITION_LOCKED=%q\n' "$ORIG_POSITION_LOCKED"
      } > "$STATE_FILE"
      chmod 0600 "$STATE_FILE"
    fi

    # p=6 is XFCE's upper-left position; p=1 is the right screen edge.
    set_value "$PANEL_PATH/position" "p=6;x=0;y=0"
    set_value "$PANEL_PATH/length" 100
    set_value "$PANEL_PATH/length-adjust" true
    set_value "$PANEL_PATH/position-locked" true
    set_value "$PANEL_PATH/size" 30
    set_value "$PANEL_PATH/icon-size" 16
    set_value "$PANEL_PATH/autohide-behavior" 0
    set_value "$PANEL_PATH/enter-opacity" 92
    set_value "$PANEL_PATH/leave-opacity" 92
    set_value "/plugins/plugin-$EXPAND_SEPARATOR/expand" true
    set_value "/plugins/plugin-$EXPAND_SEPARATOR/style" 0

    xfce4-panel -r >/dev/null 2>&1 || true
    echo
    echo "macOS-inspired top bar applied."
    echo "Existing XFCE plugins and the inactive original dock panel were preserved."
    echo "The expandable separator pushes status items to the right."
    echo "Backup: $BACKUP_XML"
    echo "Rollback: bash scripts/macos-topbar.sh rollback"
    ;;

  rollback)
    if [ ! -f "$STATE_FILE" ]; then
      echo "No saved top-bar state found; nothing changed."
      exit 0
    fi
    # State is generated locally by this script.
    # shellcheck disable=SC1090
    source "$STATE_FILE"
    PANEL_PATH="/panels/panel-1"
    set_value "$PANEL_PATH/position" "$ORIG_POSITION"
    set_value "$PANEL_PATH/length" "$ORIG_LENGTH"
    set_value "$PANEL_PATH/length-adjust" "$ORIG_LENGTH_ADJUST"
    set_value "$PANEL_PATH/size" "$ORIG_SIZE"
    set_value "$PANEL_PATH/icon-size" "$ORIG_ICON_SIZE"
    set_value "$PANEL_PATH/autohide-behavior" "$ORIG_AUTOHIDE"
    set_value "$PANEL_PATH/enter-opacity" "$ORIG_ENTER_OPACITY"
    set_value "$PANEL_PATH/leave-opacity" "$ORIG_LEAVE_OPACITY"
    set_value "$PANEL_PATH/position-locked" "$ORIG_POSITION_LOCKED"
    xfce4-panel -r >/dev/null 2>&1 || true
    rm -f "$STATE_FILE"
    echo "Top-bar geometry rolled back to its saved values."
    echo "The original inactive XFCE dock remains preserved by the Plank migration."
    ;;
esac
DEBIAN_SCRIPT
