#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

if [ -z "${PREFIX:-}" ] || [ ! -d "$PREFIX" ]; then
  echo "Run this script inside Termux." >&2
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

pkg update -y
pkg upgrade -y
pkg install -y x11-repo
pkg update -y
pkg install -y proot-distro pulseaudio termux-x11-nightly termux-api

# Termux:Widget reads executable launchers from ~/.shortcuts and background
# tasks from ~/.shortcuts/tasks. Android add-on APKs must be installed separately.
SHORTCUTS_DIR="$HOME/.shortcuts"
TASKS_DIR="$SHORTCUTS_DIR/tasks"
mkdir -p "$SHORTCUTS_DIR" "$TASKS_DIR"
chmod 700 "$SHORTCUTS_DIR" "$TASKS_DIR"
printf -v REPO_Q '%q' "$REPO_DIR"

write_shortcut() {
  local name="$1"
  local script="$2"
  cat > "$SHORTCUTS_DIR/$name" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
REPO_DIR=$REPO_Q
exec bash "\$REPO_DIR/$script"
EOF
  chmod 700 "$SHORTCUTS_DIR/$name"
}

write_shortcut "Start Debian X11" "scripts/start-desktop.sh"
write_shortcut "Stop Debian X11" "scripts/stop-desktop.sh"
write_shortcut "Check USB devices" "scripts/check-usb.sh"
write_shortcut "Start CUPS printing" "scripts/start-printing.sh"
write_shortcut "Stop CUPS printing" "scripts/stop-printing.sh"

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

write_task() {
  local name="$1"
  local script="$2"
  cat > "$TASKS_DIR/$name" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
REPO_DIR=$REPO_Q
exec bash "\$REPO_DIR/$script"
EOF
  chmod 700 "$TASKS_DIR/$name"
}
write_task "Refresh Debian desktop" "scripts/install-apps.sh"
write_task "Check USB devices" "scripts/check-usb.sh"
write_task "Install printer support" "scripts/install-printing.sh"

cat <<'EOF'

Termux host packages installed:
  - proot-distro
  - PulseAudio
  - Termux:X11 client
  - Termux:API command-line client (termux-usb)

Install the separate Termux:API Android add-on from the same signing family as Termux:
  https://github.com/termux/termux-api

Install/open Termux:X11 from a compatible source.
Termux:Widget shortcuts are created in ~/.shortcuts and ~/.shortcuts/tasks.

Install the separate Termux:Widget Android add-on from the same signing family:
  https://github.com/termux/termux-widget

Next:
  bash scripts/install-debian.sh
  bash scripts/start-desktop.sh
EOF
