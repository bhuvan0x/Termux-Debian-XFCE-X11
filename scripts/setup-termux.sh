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

# PRoot-Distro 5.8.0 contains the major filesystem/input hardening baseline
# used by this repository's isolated login workflow.
PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "ERROR: proot-distro $PD_VERSION is older than the required 5.8.0 baseline." >&2
  echo "Update Termux packages with: pkg update && pkg upgrade -y" >&2
  exit 2
fi

# Avoid recurring git pull failures caused only by Android/Termux executable
# bit differences. Content modifications are still detected normally.
if command -v git >/dev/null 2>&1 && [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" config core.filemode false
  echo "Configured repository-local Git core.filemode=false."
fi

# Provide short terminal commands as well as the two Termux:Widget buttons.
for spec in "start-all:scripts/start-all.sh" "stop-all:scripts/stop-all.sh"; do
  name="${spec%%:*}"
  script="${spec#*:}"
  cat > "$PREFIX/bin/$name" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
REPO_DIR=$REPO_DIR
if [ ! -f "\$REPO_DIR/$script" ]; then
  echo "Missing workstation script: \$REPO_DIR/$script" >&2
  exit 1
fi
exec bash "\$REPO_DIR/$script"
EOF
  chmod 700 "$PREFIX/bin/$name"
done
hash -r 2>/dev/null || true

# Exactly two daily controls in the Termux:Widget shortcuts folder.
SHORTCUTS_DIR="$HOME/.shortcuts"
TASKS_DIR="$SHORTCUTS_DIR/tasks"
mkdir -p "$SHORTCUTS_DIR" "$TASKS_DIR"
chmod 700 "$SHORTCUTS_DIR" "$TASKS_DIR"
printf -v REPO_Q '%q' "$REPO_DIR"

# Remove controls created by earlier versions.
rm -f "$SHORTCUTS_DIR/Start Debian X11" \
  "$SHORTCUTS_DIR/Stop Debian X11" \
  "$SHORTCUTS_DIR/Restart Debian X11" \
  "$SHORTCUTS_DIR/Start CUPS printing" \
  "$SHORTCUTS_DIR/Stop CUPS printing" \
  "$SHORTCUTS_DIR/Check USB devices" \
  "$SHORTCUTS_DIR/Debian Shell"

for spec in "Start All:scripts/start-all.sh" "Stop All:scripts/stop-all.sh"; do
  name="${spec%%:*}"
  script="${spec#*:}"
  cat > "$SHORTCUTS_DIR/$name" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
REPO_DIR=$REPO_Q
exec bash "\$REPO_DIR/$script"
EOF
  chmod 700 "$SHORTCUTS_DIR/$name"
done

# Maintenance tasks remain separate from the two everyday controls.
cat > "$TASKS_DIR/Update Debian packages" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
REPO_DIR=$REPO_Q
exec bash "\$REPO_DIR/scripts/update-debian.sh"
EOF
chmod 700 "$TASKS_DIR/Update Debian packages"

for spec in \
  "Harden Debian:scripts/harden-debian.sh" \
  "Security audit:scripts/security-audit.sh" \
  "Termux security check:scripts/security-check-termux.sh"; do
  name="${spec%%:*}"
  script="${spec#*:}"
  cat > "$TASKS_DIR/$name" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
REPO_DIR=$REPO_Q
exec bash "\$REPO_DIR/$script"
EOF
  chmod 700 "$TASKS_DIR/$name"
done

for spec in \
  "Refresh Debian desktop:scripts/install-apps.sh" \
  "Check USB devices:scripts/check-usb.sh" \
  "Install printer support:scripts/install-printing.sh"; do
  name="${spec%%:*}"
  script="${spec#*:}"
  cat > "$TASKS_DIR/$name" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
REPO_DIR=$REPO_Q
exec bash "\$REPO_DIR/$script"
EOF
  chmod 700 "$TASKS_DIR/$name"
done

echo
echo "Created Termux terminal commands:"
echo "  start-all"
echo "  stop-all"
echo "Created exactly two daily controls in $SHORTCUTS_DIR:"
echo "  Start All"
echo "  Stop All"
echo "Install Termux:Widget from the same signing source as Termux:"
echo "https://github.com/termux/termux-widget"
