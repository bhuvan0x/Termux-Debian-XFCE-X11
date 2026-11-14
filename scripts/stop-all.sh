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

# Stop the Termux-side X11 server process.
if command -v pkill >/dev/null 2>&1; then
  pkill -TERM -x termux-x11 2>/dev/null || true
fi

# Close the Android X11 viewer activity too.
if command -v am >/dev/null 2>&1; then
  am force-stop com.termux.x11 >/dev/null 2>&1 || true
fi

# Stop the PulseAudio instance started by the workstation.
if command -v pulseaudio >/dev/null 2>&1; then
  pulseaudio --kill >/dev/null 2>&1 || true
fi

if [ "$FAILED" -ne 0 ]; then
  echo "Stop All finished with a service warning. Review the output above." >&2
  exit 1
fi

echo "Stop All complete: XFCE, CUPS, Termux:X11 and PulseAudio shutdown requested."
