#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "\${BASH_SOURCE[0]}")" && pwd)"
echo "GNOME Software has been retired in this setup. Installing KDE Discover instead..."
exec bash "$SCRIPT_DIR/install-discover.sh" "$@"
