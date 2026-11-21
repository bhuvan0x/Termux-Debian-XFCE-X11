#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Remove only the PrimeBook Debian environment and controls created by this clone.
# Never remove shared Termux packages, other PRoot distributions, or user data.

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

Removes the Debian PRoot container and only PrimeBook-owned Termux wrappers
and Widget entries. Ubuntu, other containers, shared Termux packages,
Android add-on apps, and Android shared-storage files are preserved.

Options:
  --yes          Skip the REMOVE-DEBIAN confirmation.
  --remove-repo  Also remove this clone, but only from its expected location.
HELP
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
HOME_REAL="$(cd -- "$HOME" && pwd -P)"

owns_repo_wrapper() {
  local path="$1"
  [ -f "$path" ] && grep -Fq -- "$REPO_DIR" "$path"
}

echo "DESTRUCTIVE OPERATION: this permanently deletes the Debian PRoot filesystem."
echo "Debian applications, settings, accounts and files inside Debian will be lost."
echo "Preserved: Ubuntu/other PRoot containers, Termux, shared Termux packages,"
echo "Termux:X11/API/Widget apps, Android shared storage and unrelated shortcuts."
if [ "$REMOVE_REPO" -eq 1 ]; then
  echo "The repository clone will also be removed: $REPO_DIR"
fi

if [ "$ASSUME_YES" -ne 1 ]; then
  printf '\nType REMOVE-DEBIAN to continue: '
  IFS= read -r confirmation
  [ "$confirmation" = "REMOVE-DEBIAN" ] || { echo "Cancelled. No changes made."; exit 0; }
fi

echo
echo "== Stopping PrimeBook services =="
if [ -f "$REPO_DIR/scripts/stop-all.sh" ]; then
  bash "$REPO_DIR/scripts/stop-all.sh" || echo "WARNING: a stop action failed; continuing." >&2
fi

echo
echo "== Removing Debian container =="
if proot-distro list 2>/dev/null | grep -Eq '^[[:space:]]*\*?[[:space:]]*debian([[:space:]]|$)'; then
  proot-distro remove debian
  echo "Debian container removed."
else
  echo "Debian is not listed as installed; skipping."
fi

echo
echo "== Removing owned Termux commands =="
for command_name in start-all stop-all uninstall-primebook; do
  command_path="$PREFIX/bin/$command_name"
  if owns_repo_wrapper "$command_path"; then
    rm -f -- "$command_path"
    echo "Removed $command_name"
  else
    echo "Kept $command_name (not present or not owned by this clone)."
  fi
done
hash -r 2>/dev/null || true

echo
echo "== Removing owned Termux:Widget entries =="
SHORTCUTS_DIR="$HOME/.shortcuts"
TASKS_DIR="$SHORTCUTS_DIR/tasks"

for name in "Start All" "Stop All" "Start Debian X11" "Stop Debian X11" \
  "Restart Debian X11" "Start CUPS printing" "Stop CUPS printing" \
  "Check USB devices" "Debian Shell"; do
  path="$SHORTCUTS_DIR/$name"
  if owns_repo_wrapper "$path"; then rm -f -- "$path"; fi
done

for name in "Update Debian packages" "Refresh Debian desktop" "Check USB devices" \
  "Install printer support" "Harden Debian" "Security audit" \
  "Termux security check" "Install ClamAV" "Update ClamAV signatures" \
  "Scan Debian Downloads"; do
  path="$TASKS_DIR/$name"
  if owns_repo_wrapper "$path"; then rm -f -- "$path"; fi
done

rmdir "$TASKS_DIR" 2>/dev/null || true
rmdir "$SHORTCUTS_DIR" 2>/dev/null || true

if [ "$REMOVE_REPO" -eq 1 ]; then
  echo
  echo "== Removing repository clone =="
  case "$REPO_DIR" in
    "$HOME_REAL/Termux-Debian-X11")
      [ -d "$REPO_DIR/.git" ] || { echo "Refusing: expected Git clone not found." >&2; exit 3; }
      cd "$HOME_REAL"
      rm -rf -- "$REPO_DIR"
      echo "Repository clone removed."
      ;;
    *)
      echo "Refusing to remove unexpected repository path: $REPO_DIR" >&2
      exit 3
      ;;
  esac
fi

echo
echo "Uninstallation completed. Ubuntu and shared Termux components were left untouched."
