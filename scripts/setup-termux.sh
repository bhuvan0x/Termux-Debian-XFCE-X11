#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

if [ -z "${PREFIX:-}" ] || [ ! -d "$PREFIX" ]; then
  echo "Run this script inside Termux." >&2; exit 1
fi

pkg update -y
pkg upgrade -y
pkg install -y x11-repo
pkg update -y
pkg install -y proot-distro pulseaudio termux-x11-nightly

cat <<'EOF'
Termux side is ready.
Install/open the Termux:X11 Android application from its official project.
Next: ./scripts/install-debian.sh
EOF
