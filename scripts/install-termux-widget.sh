#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
SHORTCUTS_DIR="$HOME/.shortcuts"
TASKS_DIR="$SHORTCUTS_DIR/tasks"
mkdir -p "$SHORTCUTS_DIR" "$TASKS_DIR"
chmod 700 "$SHORTCUTS_DIR" "$TASKS_DIR"
printf -v REPO_Q '%q' "$REPO_DIR"

# Remove obsolete controls from previous versions so the widget stays simple.
rm -f "$SHORTCUTS_DIR/Start Debian X11" \
  "$SHORTCUTS_DIR/Stop Debian X11" \
  "$SHORTCUTS_DIR/Restart Debian X11" \
  "$SHORTCUTS_DIR/Start CUPS printing" \
  "$SHORTCUTS_DIR/Stop CUPS printing"

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

write_repo_shortcut "Start All" "scripts/start-all.sh"
write_repo_shortcut "Stop All" "scripts/stop-all.sh"
write_repo_shortcut "Check USB devices" "scripts/check-usb.sh"

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

echo "Created Start All and Stop All in $SHORTCUTS_DIR"
echo "USB diagnostics and Debian Shell are available as optional shortcuts."
echo "Install Termux:Widget from the same signing source as Termux:"
echo "https://github.com/termux/termux-widget"
