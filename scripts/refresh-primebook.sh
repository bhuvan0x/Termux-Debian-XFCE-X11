#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo "== PrimeBook desktop refresh =="
echo "1/2 Installing GNOME Software and its Debian/Flatpak plugins..."
bash "$SCRIPT_DIR/install-gnome-software.sh"

echo
echo "2/2 Applying early WhiteSur startup settings and restarting XFCE..."
exec bash "$SCRIPT_DIR/apply-whitesur.sh"
