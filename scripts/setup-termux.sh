#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

if [ -z "${PREFIX:-}" ] || [ ! -d "$PREFIX" ]; then
  echo "Run this script inside Termux." >&2; exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

pkg update -y
pkg upgrade -y
pkg install -y x11-repo
pkg update -y
pkg install -y proot-distro pulseaudio termux-x11-nightly

# Termux:Widget reads executable launchers from ~/.shortcuts and
# background tasks from ~/.shortcuts/tasks. The Android add-on is separate.
SHORTCUTS_DIR="$HOME/.shortcuts"
TASKS_DIR="$SHORTCUTS_DIR/tasks"
mkdir -p "$SHORTCUTS_DIR" "$TASKS_DIR"
chmod 700 "$SHORTCUTS_DIR" "$TASKS_DIR"
printf -v REPO_Q '%q' "$REPO_DIR"

cat > "$SHORTCUTS_DIR/Start Debian X11" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
REPO_DIR=$REPO_Q
exec bash "\$REPO_DIR/scripts/start-desktop.sh"
EOF

cat > "$SHORTCUTS_DIR/Stop Debian X11" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
REPO_DIR=$REPO_Q
exec bash "\$REPO_DIR/scripts/stop-desktop.sh"
EOF

cat > "$SHORTCUTS_DIR/Debian Shell" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
exec proot-distro login debian --user prime --shared-tmp
EOF

cat > "$SHORTCUTS_DIR/Restart Debian X11" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
REPO_DIR=$REPO_Q
bash "\$REPO_DIR/scripts/stop-desktop.sh"
sleep 2
exec bash "\$REPO_DIR/scripts/start-desktop.sh"
EOF

cat > "$TASKS_DIR/Update Debian packages" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
exec proot-distro login debian -- /bin/bash -lc 'apt-get update && apt-get full-upgrade -y && apt-get autoremove -y && apt-get clean'
EOF

cat > "$TASKS_DIR/Refresh Debian desktop" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
REPO_DIR=$REPO_Q
exec bash "\$REPO_DIR/scripts/install-apps.sh"
EOF

chmod 700 "$SHORTCUTS_DIR/Start Debian X11" \
  "$SHORTCUTS_DIR/Stop Debian X11" \
  "$SHORTCUTS_DIR/Debian Shell" \
  "$SHORTCUTS_DIR/Restart Debian X11" \
  "$TASKS_DIR/Update Debian packages" \
  "$TASKS_DIR/Refresh Debian desktop"

cat <<'EOF'

Termux side is ready.
Install/open the Termux:X11 Android application from its official project.
Termux:Widget shortcuts have been generated in ~/.shortcuts.

Install the separate Termux:Widget Android add-on from the same source/signing
family as Termux, then add its widget to the Android home screen:
  https://github.com/termux/termux-widget

Next:
  ./scripts/install-debian.sh
  ./scripts/install-apps.sh
  ./scripts/install-termux-widget.sh  (not needed; shortcuts are generated above)
EOF
