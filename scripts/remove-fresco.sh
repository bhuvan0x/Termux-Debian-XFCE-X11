#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

if ! command -v proot-distro >/dev/null 2>&1; then
  echo "proot-distro is missing." >&2
  exit 1
fi

proot-distro login --isolated debian -- /bin/bash -s <<'DEBIAN_SCRIPT'
set -Eeuo pipefail
PRIME_HOME="$(getent passwd prime | cut -d: -f6)"
if [ -z "$PRIME_HOME" ] || [ ! -d "$PRIME_HOME" ]; then
  echo "Could not resolve the prime desktop user's home." >&2
  exit 1
fi

rm -f /usr/local/bin/fresco /usr/local/bin/frescod
rm -f "$PRIME_HOME/.local/share/applications/fresco.desktop"
if command -v update-desktop-database >/dev/null 2>&1; then
  runuser -u prime -- env HOME="$PRIME_HOME" \
    XDG_DATA_HOME="$PRIME_HOME/.local/share" \
    update-desktop-database "$PRIME_HOME/.local/share/applications" >/dev/null 2>&1 || true
fi
echo "Removed the Fresco binaries and XFCE launcher."
echo "Fresco source, build files, configuration and wallpaper library were left untouched."
DEBIAN_SCRIPT
