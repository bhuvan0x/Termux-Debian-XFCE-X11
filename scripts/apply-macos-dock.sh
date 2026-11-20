#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Apply a macOS-inspired floating dock and fast XFCE app finders.
# Run from Termux while the Debian XFCE desktop is running.

command -v proot-distro >/dev/null 2>&1 || {
  echo "proot-distro is missing. Run scripts/setup-termux.sh first." >&2
  exit 1
}

PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Update Termux proot-distro to version 5.8.0 or newer first." >&2
  exit 2
fi

echo "== Configuring the live Debian XFCE session =="

if [ -e "$HOME/.config/primebook/plank-enabled" ]; then
  echo "Plank mode is active. Run scripts/plank-dock.sh rollback before reapplying the XFCE dock profile." >&2
  exit 3
fi

proot-distro login --isolated --shared-x11 --user prime debian -- /bin/bash -s <<'DEBIAN_SCRIPT'
set -Eeuo pipefail
export DISPLAY="${DISPLAY:-:0}"

# Find the live XFCE session without filtering by the PRoot-visible UID.
# PRoot's UID translation can make pgrep -u miss processes that are visible
# in /proc. Never trust ~/.dbus/session-bus here: dbus-launch may leave a
# stale file for a short-lived helper bus rather than the desktop bus.
SESSION_PID=""
DBUS_ADDRESS=""
for candidate_pid in $(pgrep -x xfce4-session 2>/dev/null || true); do
  [ -r "/proc/$candidate_pid/environ" ] || continue
  candidate_address="$(tr '\0' '\n' < "/proc/$candidate_pid/environ" | sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p' | head -n 1)"
  [ -n "$candidate_address" ] || continue
  if DBUS_SESSION_BUS_ADDRESS="$candidate_address" \
      xfconf-query -c xfce4-panel -p /panels >/dev/null 2>&1; then
    SESSION_PID="$candidate_pid"
    DBUS_ADDRESS="$candidate_address"
    break
  fi
done

if [ -z "$DBUS_ADDRESS" ]; then
  echo "ERROR: Could not locate the live XFCE session D-Bus."
  echo "No running xfce4-session process exposed a working panel Xfconf channel."
  echo "Start the desktop with 'start-all', then rerun this script from Termux."
  exit 3
fi
export DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDRESS"

if ! xfconf-query -c xsettings -p /Net/ThemeName >/dev/null 2>&1; then
  echo "ERROR: The live XFCE session bus was found but Xfconf is not responding."
  exit 4
fi
echo "Connected to XFCE session PID $SESSION_PID."

set_int() {
  xfconf-query -c "$1" -p "$2" --create -t int -s "$3" >/dev/null
}
set_uint() {
  xfconf-query -c "$1" -p "$2" --create -t uint -s "$3" >/dev/null
}
set_bool() {
  xfconf-query -c "$1" -p "$2" --create -t bool -s "$3" >/dev/null
}
set_string() {
  xfconf-query -c "$1" -p "$2" --create -t string -s "$3" >/dev/null
}

# Identify the existing auto-hidden panel (the user's bottom panel).
# If no panel currently auto-hides, use the last configured panel.
mapfile -t PANEL_IDS < <(xfconf-query -c xfce4-panel -p /panels 2>/dev/null | sed -nE '/^[[:space:]]*[0-9]+[[:space:]]*$/s/^[[:space:]]*([0-9]+)[[:space:]]*$/\1/p' | sort -nu)
if [ "${#PANEL_IDS[@]}" -eq 0 ]; then
  echo "ERROR: No XFCE panels were found; nothing was changed."
  exit 5
fi

DOCK_PANEL=""
for id in "${PANEL_IDS[@]}"; do
  behavior="$(xfconf-query -c xfce4-panel -p "/panels/panel-$id/autohide-behavior" 2>/dev/null || true)"
  if [ "$behavior" = "1" ] || [ "$behavior" = "2" ]; then DOCK_PANEL="$id"; fi
done
if [ -z "$DOCK_PANEL" ]; then
  PANEL_LAST_INDEX=$(("${#PANEL_IDS[@]}" - 1))
  DOCK_PANEL="${PANEL_IDS[$PANEL_LAST_INDEX]}"
fi
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

echo "Using existing panel: panel-$DOCK_PANEL"

# Floating dock: retain all existing panel items and their order. A 52%
# length creates side margins; auto-hide reveals it when the pointer reaches
# the bottom screen edge. XFCE's native panel has no icon magnification.
set_int xfce4-panel "$DOCK/length" 52
set_bool xfce4-panel "$DOCK/length-adjust" false
set_bool xfce4-panel "$DOCK/position-locked" true
set_string xfce4-panel "$DOCK/position" "p=10;x=0;y=0"
set_int xfce4-panel "$DOCK/size" 50
set_int xfce4-panel "$DOCK/icon-size" 34
set_int xfce4-panel "$DOCK/autohide-behavior" 2
set_int xfce4-panel "$DOCK/background-style" 0
set_int xfce4-panel "$DOCK/enter-opacity" 100
set_int xfce4-panel "$DOCK/leave-opacity" 100

# Make the existing tasklist behave like an icon dock; do not add, delete,
# reorder or replace any panel plugins or launchers.
while IFS= read -r line; do
  plugin_path="${line%%:*}"
  plugin_type="${line#*: }"
  [[ "$plugin_path" =~ ^/plugins/plugin-([0-9]+)$ ]] || continue
  plugin_id="${BASH_REMATCH[1]}"
  case "$plugin_type" in
    tasklist)
      set_bool xfce4-panel "/plugins/plugin-$plugin_id/show-labels" false
      set_bool xfce4-panel "/plugins/plugin-$plugin_id/flat-buttons" true
      set_bool xfce4-panel "/plugins/plugin-$plugin_id/show-handle" false
      set_bool xfce4-panel "/plugins/plugin-$plugin_id/show-tooltips" true
      set_int xfce4-panel "/plugins/plugin-$plugin_id/grouping" 1
      ;;
    docklike)
      # Keep Docklike's existing launcher/task grouping configuration.
      ;;
  esac
done < <(xfconf-query -c xfce4-panel -lv 2>/dev/null || true)

# Spotlight-style compact search: Super+Space.
# Launchpad-style expanded application grid: Super+E.
set_string xfce4-keyboard-shortcuts '/commands/custom/<Super>space' 'xfce4-appfinder --collapsed'
set_string xfce4-keyboard-shortcuts '/commands/custom/<Super>e' 'xfce4-appfinder --expanded'

# Liquid-glass-inspired surface shared with the full WhiteSur installer.
mkdir -p "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-3.0/gtk.css" <<'GLASS_CSS'
#XfcePanelWindow {
  background-color: rgba(20, 24, 38, 0.92);
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

# Refresh only the panel. No XFCE session, audio, CUPS or X11 restart.
xfce4-panel -r >/dev/null 2>&1 || true

echo
echo "Applied:"
echo "  Bottom panel: 52% width, bottom-centered icon group, stronger dark-glass styling, always auto-hide"
echo "  Super+Space:  compact Spotlight-style app search"
echo "  Super+E:      expanded Launchpad-style app grid"
echo "  Existing panel items and launchers: preserved"
echo
echo "Current GTK theme: $(xfconf-query -c xsettings -p /Net/ThemeName)"
DEBIAN_SCRIPT

echo
echo "Done. Move the pointer to the bottom edge to reveal the floating dock."
echo "Press Super+Space for instant search or Super+E for the expanded app grid."
