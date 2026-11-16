#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
echo "== PrimeBook desktop refresh =="
echo "1/2 Installing KDE Discover and its Flatpak backend..."
bash "$SCRIPT_DIR/install-discover.sh"
echo
echo "2/2 Applying early WhiteSur startup settings and restarting XFCE..."
exec bash "$SCRIPT_DIR/apply-whitesur.sh"
