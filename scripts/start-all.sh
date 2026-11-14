#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
START_SCRIPT="$SCRIPT_DIR/start-desktop.sh"

if [ ! -f "$START_SCRIPT" ]; then
  echo "Missing start-desktop.sh in $SCRIPT_DIR" >&2
  exit 1
fi

echo "Starting PrimeBook workstation: Termux:X11, audio, CUPS and XFCE..."
exec bash "$START_SCRIPT"
