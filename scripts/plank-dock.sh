#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Reversible Plank migration for the PrimeBook XFCE desktop.
# Usage: bash scripts/plank-dock.sh install|rollback|status

ACTION="${1:-}"
case "$ACTION" in
  install|rollback|status) ;;
  *) echo "Usage: bash scripts/plank-dock.sh {install|rollback|status}" >&2; exit 2 ;;
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
CONFIG_DIR="$HOME/.config/primebook"
STATE_FILE="$CONFIG_DIR/plank-panel-state"
MARKER="$CONFIG_DIR/plank-enabled"
AUTOSTART="$HOME/.config/autostart/plank.desktop"
mkdir -p "$CONFIG_DIR" "$HOME/.config/autostart" "$HOME/.cache"

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

case "$ACTION" in
  status)
    echo "Plank package: $(dpkg-query -W -f='${Status} ${Version}' plank 2>/dev/null || echo not-installed)"
    if [ -e "$MARKER" ]; then
      echo "Migration: enabled"
      cat "$STATE_FILE" 2>/dev/null || true
      pgrep -a -x plank || true
    else
      echo "Migration: disabled (XFCE dock profile remains in control)"
    fi
    ;;

  install)
    if [ -e "$MARKER" ]; then
      echo "Plank migration is already enabled."
      echo "Use 'status' to inspect it or 'rollback' to restore the XFCE dock."
      exit 0
    fi
    if ! find_session_bus; then
      echo "ERROR: No live XFCE session D-Bus was found."
      echo "Start the desktop with start-all, then rerun this command."
      exit 3
    fi
    mapfile -t PANEL_IDS < <(xfconf-query -c xfce4-panel -p /panels 2>/dev/null | sed -nE '/^[[:space:]]*[0-9]+[[:space:]]*$/s/^[[:space:]]*([0-9]+)[[:space:]]*$/\1/p' | sort -nu)
    if [ "${#PANEL_IDS[@]}" -eq 0 ]; then
      echo "ERROR: No XFCE panel was found; refusing to modify the desktop."
      exit 4
    fi
    DOCK_PANEL=""
    for id in "${PANEL_IDS[@]}"; do
      position="$(xfconf-query -c xfce4-panel -p "/panels/panel-$id/position" 2>/dev/null || true)"
      behavior="$(xfconf-query -c xfce4-panel -p "/panels/panel-$id/autohide-behavior" 2>/dev/null || true)"
      if [[ "$position" == p=10* ]] || [ "$behavior" = "2" ]; then DOCK_PANEL="$id"; fi
    done
    if [ -z "$DOCK_PANEL" ]; then
      echo "ERROR: Could not identify the bottom/dock panel unambiguously."
      echo "No panel settings were changed. Inspect: xfconf-query -c xfce4-panel -lv"
      exit 5
    fi
    PREVIOUS_AUTOHIDE="$(xfconf-query -c xfce4-panel -p "/panels/panel-$DOCK_PANEL/autohide-behavior" 2>/dev/null || echo 0)"
    case "$PREVIOUS_AUTOHIDE" in 0|1|2) ;; *) echo "ERROR: Unexpected autohide value: $PREVIOUS_AUTOHIDE"; exit 6;; esac

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y plank

    # Persist only the exact panel property this migration changes.
    {
      printf 'panel_id=%s\n' "$DOCK_PANEL"
      printf 'autohide_behavior=%s\n' "$PREVIOUS_AUTOHIDE"
    } > "$STATE_FILE"
    chmod 0600 "$STATE_FILE"

    # Plank replaces the bottom dock role. Keep the XFCE panel's launchers,
    # plugins and geometry untouched; its previous auto-hide value is saved.
    xfconf-query -c xfce4-panel -p "/panels/panel-$DOCK_PANEL/autohide-behavior" --create -t int -s 2
    touch "$MARKER"

    cat > "$AUTOSTART" <<'PLANK_AUTOSTART'
[Desktop Entry]
Type=Application
Name=Plank Dock
Comment=PrimeBook application dock
Exec=plank
OnlyShowIn=XFCE;
StartupNotify=false
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
PLANK_AUTOSTART
    chmod 0644 "$AUTOSTART"

    if ! pgrep -x plank >/dev/null 2>&1; then
      nohup plank >"$HOME/.cache/plank.log" 2>&1 </dev/null &
    fi
    sleep 2
    echo
    echo "Plank migration enabled."
    echo "XFCE panel $DOCK_PANEL remains installed and its original autohide value is saved."
    echo "Plank log: $HOME/.cache/plank.log"
    echo "Use Ctrl + right-click on Plank to open Preferences."
    echo "If the two docks compete at the bottom edge, run: bash scripts/plank-dock.sh rollback"
    ;;

  rollback)
    if [ ! -e "$MARKER" ] || [ ! -f "$STATE_FILE" ]; then
      echo "No complete Plank migration state was found; nothing was changed."
      exit 0
    fi
    if ! find_session_bus; then
      echo "ERROR: No live XFCE session D-Bus was found."
      echo "Start the desktop with start-all, then rerun rollback."
      exit 3
    fi
    # State file is generated by this script and contains only numeric values.
    # shellcheck disable=SC1090
    source "$STATE_FILE"
    case "${panel_id:-}" in ''|*[!0-9]*) echo "Invalid saved panel ID; refusing rollback."; exit 7;; esac
    case "${autohide_behavior:-}" in 0|1|2) ;; *) echo "Invalid saved autohide value; refusing rollback."; exit 7;; esac

    pkill -TERM -x plank 2>/dev/null || true
    rm -f "$AUTOSTART"
    xfconf-query -c xfce4-panel -p "/panels/panel-$panel_id/autohide-behavior" --create -t int -s "$autohide_behavior"
    rm -f "$MARKER" "$STATE_FILE"
    xfce4-panel -r >/dev/null 2>&1 || true
    echo "Rollback complete. The original XFCE panel auto-hide setting has been restored."
    echo "Plank remains installed but is no longer autostarted; remove it later with apt if desired."
    ;;
esac
DEBIAN_SCRIPT
