#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
SHORTCUTS_DIR="$HOME/.shortcuts"
TASKS_DIR="$SHORTCUTS_DIR/tasks"
mkdir -p "$SHORTCUTS_DIR" "$TASKS_DIR"
chmod 700 "$SHORTCUTS_DIR" "$TASKS_DIR"
printf -v REPO_Q '%q' "$REPO_DIR"

write_repo_shortcut() {
  local name="$1" script="$2"
  cat > "$SHORTCUTS_DIR/$name" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
REPO_DIR=$REPO_Q
exec bash "\$REPO_DIR/$script"
EOF
  chmod 700 "$SHORTCUTS_DIR/$name"
}

write_repo_shortcut "Start Debian X11" "scripts/start-desktop.sh"
write_repo_shortcut "Stop Debian X11" "scripts/stop-desktop.sh"
write_repo_shortcut "Check USB devices" "scripts/check-usb.sh"
write_repo_shortcut "Start CUPS printing" "scripts/start-printing.sh"
write_repo_shortcut "Stop CUPS printing" "scripts/stop-printing.sh"

cat > "$SHORTCUTS_DIR/Restart Debian X11" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
REPO_DIR=$REPO_Q
bash "\$REPO_DIR/scripts/stop-desktop.sh"
sleep 2
exec bash "\$REPO_DIR/scripts/start-desktop.sh"
EOF
chmod 700 "$SHORTCUTS_DIR/Restart Debian X11"

cat > "$SHORTCUTS_DIR/Debian Shell" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
exec proot-distro login debian --user prime --shared-tmp
EOF
chmod 700 "$SHORTCUTS_DIR/Debian Shell"

cat > "$TASKS_DIR/Update Debian packages" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
exec proot-distro login debian -- /bin/bash -lc 'apt-get update && apt-get full-upgrade -y && apt-get autoremove -y && apt-get clean'
EOF
chmod 700 "$TASKS_DIR/Update Debian packages"

write_repo_task() {
  local name="$1" script="$2"
  cat > "$TASKS_DIR/$name" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
REPO_DIR=$REPO_Q
exec bash "\$REPO_DIR/$script"
EOF
  chmod 700 "$TASKS_DIR/$name"
}
write_repo_task "Refresh Debian desktop" "scripts/install-apps.sh"
write_repo_task "Check USB devices" "scripts/check-usb.sh"
write_repo_task "Install printer support" "scripts/install-printing.sh"

echo "Termux:Widget shortcuts created in $SHORTCUTS_DIR"
echo "Background tasks created in $TASKS_DIR"
echo "Install Termux:Widget from the same signing source as Termux:"
echo "https://github.com/termux/termux-widget"
echo "For USB permission dialogs also install Termux:API:"
echo "https://github.com/termux/termux-api"
echo "Then add the Termux:Widget from Android's home-screen widget picker."
