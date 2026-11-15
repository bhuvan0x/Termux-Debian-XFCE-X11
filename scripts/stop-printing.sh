#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
command -v proot-distro >/dev/null 2>&1 || { echo "proot-distro is missing." >&2; exit 1; }
proot-distro login --isolated debian -- /bin/bash -lc '
  if pgrep -x cupsd >/dev/null 2>&1; then
    pkill -TERM -x cupsd
    echo "CUPS stop signal sent."
  else
    echo "CUPS is not running."
  fi
'
