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

# Stop the Debian desktop and printing service before host-side daemons.
run_stop "XFCE desktop" "$SCRIPT_DIR/stop-desktop.sh"
run_stop "CUPS printing" "$SCRIPT_DIR/stop-printing.sh"

# These are the host-side services started by start-desktop.sh.
if command -v pkill >/dev/null 2>&1; then
  pkill -TERM -x termux-x11 2>/dev/null || true
  pkill -TERM -f '(^|/)termux-x11 :0 >/dev/null 2>&1; then
  pulseaudio --kill >/dev/null 2>&1 || true
fi

if [ "$FAILED" -ne 0 ]; then
  echo "Stop-all finished with a service warning. Review the output above." >&2
  exit 1
fi

echo "Everything started by this workstation has been stopped."
echo "Termux:X11 viewer, server, XFCE, CUPS and PulseAudio shutdown requested."
 2>/dev/null || true
fi

# Close the Android viewer activity as well as the Termux-side X11 server.
if command -v am >/dev/null 2>&1; then
  am force-stop com.termux.x11 >/dev/null 2>&1 || true
fi

if command -v pulseaudio >/dev/null 2>&1; then
  pulseaudio --kill >/dev/null 2>&1 || true
fi

if [ "$FAILED" -ne 0 ]; then
  echo "Stop-all finished with a service warning. Review the output above." >&2
  exit 1
fi

echo "Everything started by this workstation has been stopped."
echo "The Termux:X11 Android window may remain open; close it if needed."
