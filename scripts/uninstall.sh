#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Remove the PrimeBook Debian environment and its Termux-side controls.
# This intentionally preserves Termux, shared Termux packages, Android add-ons,
# Android shared-storage files, and every other PRoot-Distro container.

if [ -z "${PREFIX:-}" ] || [ ! -d "$PREFIX" ] || ! command -v proot-distro >/dev/null 2>&1; then
  echo "Run this script from Termux with proot-distro installed." >&2
  exit 1
fi

REMOVE_REPO=0
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --remove-repo) REMOVE_REPO=1 ;;
    --yes) ASSUME_YES=1 ;;
    -h|--help)
      cat <<'HELP'
Usage: bash scripts/uninstall.sh [--yes] [--remove-repo]

Removes the Debian PRoot-Distro container and PrimeBook-created Termux
commands/widgets. It preserves Ubuntu and other containers, Termux itself,
shared Termux packages, Termux:X11/API/Widget apps, and Android files.

Options:
  --yes          Skip the REMOVE-DEBIAN confirmation.
  --remove-repo  Also delete this repository clone after all cleanup.
HELP
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

echo "============================================================"
echo " PrimeBook / Debian workstation removal"
echo "============================================================"
echo "This will permanently delete the Debian PRoot filesystem."
echo "Installed Debian applications, settings, and files inside Debian"
echo "will be lost unless backed up first."
echo
echo "It will NOT remove:"
echo "  - Termux or shared Termux packages"
echo "  - Ubuntu or any other PRoot-Distro container"
echo "  - Termux:X11, Termux:API, or Termux:Widget Android apps"
echo "  - Files in Android shared storage"
if [ "$REMOVE_REPO" -eq 1 ]; then
  echo "  - (Repository clone WILL also be deleted: $REPO_DIR)"
else
  echo "  - This Git repository clone (unless --remove-repo is supplied)"
fi
echo

if [ "$ASSUME_YES" -ne 1 ]; then
  read -r -p 'Type REMOVE-DEBIAN to continue: ' confirmation
  if [ "$confirmation" != "REMOVE-DEBIAN" ]; then
    echo "Cancelled. No changes made."
    exit 0
  fi
fi

echo
echo "== Stopping PrimeBook desktop services =="
if [ -f "$REPO_DIR/scripts/stop-all.sh" ]; then
  if ! bash "$REPO_DIR/scripts/stop-all.sh"; then
    echo "WARNING: one or more services did not report a clean stop; continuing." >&2
  fi
else
  echo "Stop script not found; continuing with container removal."
fi

echo
echo "== Removing Debian container =="
if proot-distro list 2>/dev/null | awk '$1 == "*" && $2 == "debian" { found=1 } END { exit !found }'; then
  proot-distro remove debian
  echo "Debian container removed."
else
  echo "Debian is not listed as installed; skipping container removal."
fi

echo
echo "== Removing PrimeBook Termux commands =="
for command_name in start-all stop-all uninstall-primebook; do
  if [ -e "$PREFIX/bin/$command_name" ]; then
    rm -f -- "$PREFIX/bin/$command_name"
    echo "Removed $command_name"
  fi
done
hash -r 2>/dev/null || true

echo
echo "== Removing PrimeBook Termux:Widget entries =="
SHORTCUTS_DIR="$HOME/.shortcuts"
TASKS_DIR="$SHORTCUTS_DIR/tasks"

for name in \
  "Start All" "Stop All" \
  "Start Debian X11" "Stop Debian X11" "Restart Debian X11" \
  "Start CUPS printing" "Stop CUPS printing" "Check USB devices" "Debian Shell"; do
  rm -f -- "$SHORTCUTS_DIR/$name"
done

for name in \
  "Update Debian packages" "Refresh Debian desktop" "Check USB devices" \
  "Install printer support" "Harden Debian" "Security audit" \
  "Termux security check" "Install ClamAV" "Update ClamAV signatures" \
  "Scan Debian Downloads"; do
  rm -f -- "$TASKS_DIR/$name"
done

# Remove only the now-empty directories; preserve unrelated user shortcuts/tasks.
rmdir "$TASKS_DIR" 2>/dev/null || true
rmdir "$SHORTCUTS_DIR" 2>/dev/null || true

if [ "$REMOVE_REPO" -eq 1 ]; then
  echo
  echo "== Removing repository clone =="
  case "$REPO_DIR" in
    "$HOME"/*/Termux-Debian-X11)
      rm -rf -- "$REPO_DIR"
      echo "Repository clone removed."
      ;;
    *)
      echo "Refusing to remove unexpected repository path: $REPO_DIR" >&2
      exit 1
      ;;
  esac
fi

echo
echo "PrimeBook Debian removal finished."
echo "Ubuntu and shared Termux components were left untouched."
