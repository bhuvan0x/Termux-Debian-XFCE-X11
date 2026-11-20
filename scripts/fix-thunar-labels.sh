#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Repair Thunar's GTK3 file-view label contrast for the persistent prime user.
# Run from Termux; this script does not reset the user's XFCE appearance.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
command -v proot-distro >/dev/null 2>&1 || {
  echo "proot-distro is missing. Run scripts/setup-termux.sh first." >&2
  exit 1
}
PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Update Termux proot-distro to version 5.8.0 or newer first." >&2
  exit 2
fi

echo "Applying the Thunar-only GTK3 label contrast repair..."

proot-distro login --isolated --user prime debian -- /bin/bash -s <<'DEBIAN_SCRIPT'
set -Eeuo pipefail
CSS="$HOME/.config/gtk-3.0/gtk.css"
mkdir -p "$(dirname "$CSS")"
touch "$CSS"

# Remove the earlier experimental overrides from this troubleshooting session,
# keeping the pre-existing WhiteSur/PrimeBook panel styling intact.
TMP="$(mktemp)"
awk '
  /^\/\* PrimeBook Thunar folder-name visibility fix \*\// { exit }
  /^\/\* Strong Thunar icon-view label contrast \*\// { exit }
  /^\/\* Force readable text throughout GTK file views \*\// { exit }
  { print }
' "$CSS" > "$TMP"
cat "$TMP" > "$CSS"
rm -f "$TMP"

cat >> "$CSS" <<'THUNAR_CSS'

/* BEGIN PrimeBook managed Thunar label-contrast repair */
ThunarWindow iconview.view cell,
ThunarWindow iconview.view cell text,
ThunarWindow iconview.view cell label,
ThunarWindow .view,
ThunarWindow .view text,
ThunarWindow .view label,
ThunarWindow treeview.view,
ThunarWindow treeview.view cell,
ThunarWindow treeview.view cell text {
    color: #f5f7ff;
}

ThunarWindow iconview.view cell {
    background-color: #252a33;
}

ThunarWindow iconview.view cell:selected,
ThunarWindow iconview.view cell:selected text,
ThunarWindow iconview.view cell:selected label,
ThunarWindow treeview.view:selected,
ThunarWindow treeview.view:selected text {
    color: #ffffff;
    background-color: #1769aa;
}
/* END PrimeBook managed Thunar label-contrast repair */
THUNAR_CSS

chmod 0644 "$CSS"

# Ensure common GTK fonts are installed; this is additive and does not change
# the selected Noto Sans font or any XFCE appearance settings.
if command -v apt-get >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y fonts-noto-core fonts-dejavu-core
fi

echo "Updated: $CSS"
echo "Restart Thunar or log out of XFCE and run start-all."
DEBIAN_SCRIPT

echo
echo "Thunar label-contrast repair applied. Restart the desktop with:"
echo "  stop-all"
echo "  start-all"
