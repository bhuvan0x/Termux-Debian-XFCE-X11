#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FAILED=0

run_stop() {
  local label="$1"
  local script="$2"
  if [ -f "$script" ]; then
    echo "Stopping $label..."
    bash "$script" || FAILED=1
  fi
}

# Stop the Debian desktop and print scheduler first.
run_stop "XFCE desktop" "$SCRIPT_DIR/stop-desktop.sh"
run_stop "CUPS printing" "$SCRIPT_DIR/stop-printing.sh"

# Close the Android Termux:X11 viewer using its documented stop action.
# The viewer Activity and the Termux-side X server are separate processes.
if command -v am >/dev/null 2>&1; then
  echo "Closing Termux:X11 viewer..."
  am broadcast -a com.termux.x11.ACTION_STOP -p com.termux.x11 >/dev/null 2>&1 || true
fi

# Stop the Termux-side X11 server. Match its command line rather than only
# the process name because builds may expose different process comm values.
if command -v pkill >/dev/null 2>&1; then
  pkill -TERM -f '[t]ermux-x11' 2>/dev/null || true
fi

# Stop the PulseAudio instance started by the workstation.
if command -v pulseaudio >/dev/null 2>&1; then
  pulseaudio --kill >/dev/null 2>&1 || true
fi

if [ "$FAILED" -ne 0 ]; then
  echo "Stop All finished with a service warning. Review the output above." >&2
  exit 1
fi

echo "Stop All complete: XFCE, CUPS, Termux:X11 viewer/server and PulseAudio shutdown requested."
