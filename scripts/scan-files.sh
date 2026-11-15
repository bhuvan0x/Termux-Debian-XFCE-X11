#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

if [ -z "${PREFIX:-}" ] || ! command -v proot-distro >/dev/null 2>&1; then
  echo "Run this script from Termux." >&2
  exit 1
fi
PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Update proot-distro to 5.8.0 or newer before scanning." >&2
  exit 2
fi
SCAN_PATH="${1:-/home/prime/Downloads}"
case "$SCAN_PATH" in
  /*) ;;
  *) echo "Use an absolute path inside Debian, for example /home/prime/Downloads." >&2; exit 2 ;;
esac
case "$SCAN_PATH" in
  /|/proc|/proc/*|/sys|/sys/*|/dev|/dev/*|/run|/run/*)
    echo "Refusing to recursively scan a virtual/system filesystem: $SCAN_PATH" >&2
    exit 2
    ;;
esac

proot-distro login --isolated debian -- /usr/bin/env "SCAN_PATH=$SCAN_PATH" /bin/bash -s <<'CLAMAV_SCAN'
set -u
if ! command -v clamscan >/dev/null 2>&1; then
  echo "ClamAV is not installed. Run: bash scripts/install-clamav.sh" >&2
  exit 127
fi
if [ ! -e "$SCAN_PATH" ]; then
  echo "Path not found inside isolated Debian: $SCAN_PATH" >&2
  echo "Only paths inside Debian are visible by default; Android shared storage is intentionally not mounted."
  exit 2
fi
LOG="/home/prime/Documents/clamav-scan.log"
mkdir -p /home/prime/Documents
printf 'ClamAV version: '; clamscan --version
printf 'Scan target: %s\n' "$SCAN_PATH"
echo "Scanning may take time. Large archives and files can be skipped by ClamAV's configured scan limits."
set +e
clamscan --recursive --infected --log="$LOG" -- "$SCAN_PATH"
status=$?
set -e
echo "Scan log: $LOG"
case "$status" in
  0) echo "No detections in files scanned."; exit 0 ;;
  1) echo "DETECTION: review the report. No files were deleted or quarantined."; exit 1 ;;
  *) echo "ClamAV scanner error (exit $status). Check the database and log."; exit "$status" ;;
esac
CLAMAV_SCAN
