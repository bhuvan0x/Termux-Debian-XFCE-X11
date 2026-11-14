#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
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
cat > "$SHORTCUTS_DIR/Restart Debian X11" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
REPO_DIR=$REPO_Q
bash "\$REPO_DIR/scripts/stop-desktop.sh"
sleep 2
exec bash "\$REPO_DIR/scripts/start-desktop.sh"
EOF
cat > "$SHORTCUTS_DIR/Debian Shell" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
exec proot-distro login debian --user prime --shared-tmp
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
bash "\$REPO_DIR/scripts/install-apps.sh"
EOF

chmod 700 "$SHORTCUTS_DIR/Start Debian X11" \
  "$SHORTCUTS_DIR/Stop Debian X11" \
  "$SHORTCUTS_DIR/Restart Debian X11" \
  "$SHORTCUTS_DIR/Debian Shell" \
  "$TASKS_DIR/Update Debian packages" \
  "$TASKS_DIR/Refresh Debian desktop"

echo "Termux:Widget launchers created in $SHORTCUTS_DIR"
echo "Background tasks created in $TASKS_DIR"
echo "Install the Termux:Widget Android add-on from the same source/signing family as Termux:"
echo "https://github.com/termux/termux-widget"
echo "Then add the Termux:Widget widget from Android's home-screen widget picker."
