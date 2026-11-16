#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

MODE="${1:-install}"
if [[ "$MODE" != install && "$MODE" != --remove ]]; then
  echo "Usage: bash scripts/install-modernclock.sh [--remove]" >&2
  exit 2
fi
command -v proot-distro >/dev/null 2>&1 || {
  echo "proot-distro is required. Install the Debian environment first." >&2
  exit 1
}
command -v git >/dev/null 2>&1 || {
  echo "Git is required. Install it with: pkg install git" >&2
  exit 1
}

TMP_ROOT="${TMPDIR:-${PREFIX:-$HOME}/tmp}"
mkdir -p "$TMP_ROOT"
WORK_DIR="$(mktemp -d "$TMP_ROOT/modern-gaming-clock.XXXXXX")"
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

echo "== Fetching the shared Modern Gaming Clock source =="
git clone --depth 1 --quiet https://github.com/bhuvan0x/Mordern_Gaming_Clock.git "$WORK_DIR/source"

set +e
bash "$WORK_DIR/source/install.sh" "$MODE"
status=$?
set -e
exit "$status"
