#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Remove the experimental Thunar CSS overrides added during troubleshooting.
# This restores the original GTK stylesheet content without resetting the
# selected WhiteSur theme, XFCE panels, dock, fonts, or other preferences.

command -v proot-distro >/dev/null 2>&1 || {
  echo "proot-distro is missing." >&2
  exit 1
}
PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Update Termux proot-distro to version 5.8.0 or newer first." >&2
  exit 2
fi

echo "Removing only the experimental Thunar CSS overrides..."

proot-distro login --isolated --user prime debian -- /bin/bash -s <<'DEBIAN_SCRIPT'
set -Eeuo pipefail
CSS="$HOME/.config/gtk-3.0/gtk.css"
if [ ! -f "$CSS" ]; then
  echo "No GTK stylesheet found; nothing to clean."
  exit 0
fi

BACKUP="$CSS.before-thunar-css-cleanup-$(date +%Y%m%d-%H%M%S)"
cp -p "$CSS" "$BACKUP"

TMP="$(mktemp)"
awk '
  /^\/\* PrimeBook Thunar folder-name visibility fix \*\// { skip=1 }
  /^\/\* Strong Thunar icon-view label contrast \*\// { skip=1 }
  /^\/\* Force readable text throughout GTK file views \*\// { skip=1 }
  /^\/\* BEGIN PrimeBook managed Thunar label-contrast repair \*\// { skip=1 }
  !skip { print }
' "$CSS" > "$TMP"

cat "$TMP" > "$CSS"
rm -f "$TMP"
chmod 0644 "$CSS"

echo "Removed the experimental Thunar rules."
echo "Backup: $BACKUP"
echo "Preserved all stylesheet content preceding those rules."
DEBIAN_SCRIPT

echo
echo "Now restart Thunar, or run stop-all then start-all."
