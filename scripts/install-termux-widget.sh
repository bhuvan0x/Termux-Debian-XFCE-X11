#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

if [ -z "${PREFIX:-}" ] || [ ! -d "$PREFIX" ]; then
  echo "Run this script inside Termux." >&2
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
SHORTCUTS_DIR="$HOME/.shortcuts"
TASKS_DIR="$SHORTCUTS_DIR/tasks"
mkdir -p "$SHORTCUTS_DIR" "$TASKS_DIR"
chmod 700 "$SHORTCUTS_DIR" "$TASKS_DIR"
printf -v REPO_Q '%q' "$REPO_DIR"

# Keep git pull reliable on Android filesystems where executable-bit changes
# can otherwise appear as local modifications.
if command -v git >/dev/null 2>&1 && [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" config core.filemode false
fi

# Install short terminal commands from any working directory.
printf -v REPO_Q '%q' "$REPO_DIR"
for spec in "start-all:scripts/start-all.sh" "stop-all:scripts/stop-all.sh" "uninstall-primebook:scripts/uninstall.sh"; do
  name="${spec%%:*}"
  script="${spec#*:}"
  target="$PREFIX/bin/$name"
  if [ -e "$target" ] && ! grep -Fq -- "$REPO_DIR" "$target"; then
    echo "Refusing to overwrite existing non-PrimeBook command: $target" >&2
    exit 3
  fi
  cat > "$target" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
REPO_DIR=$REPO_Q
if [ ! -f "\$REPO_DIR/$script" ]; then
  echo "Missing workstation script: \$REPO_DIR/$script" >&2
  exit 1
fi
exec bash "\$REPO_DIR/$script"
EOF
  chmod 700 "$target"
done
hash -r 2>/dev/null || true

# Remove individual start/stop controls from older versions.
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

# Keep maintenance actions in the optional Widget tasks list.
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
  "Termux security check:scripts/security-check-termux.sh" \
  "Install ClamAV:scripts/install-clamav.sh" \
  "Update ClamAV signatures:scripts/update-clamav.sh" \
  "Scan Debian Downloads:scripts/scan-files.sh"; do
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

echo "Created terminal commands: start-all and stop-all."
echo "Created exactly two daily Widget controls: Start All and Stop All."
echo "Install Termux:Widget from the same signing source as Termux:"
echo "https://github.com/termux/termux-widget"
