#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
command -v proot-distro >/dev/null 2>&1 || { echo "proot-distro is missing." >&2; exit 1; }
proot-distro login debian -- /bin/bash -lc '
  if [ ! -x /usr/sbin/cupsd ]; then
    echo "CUPS is not installed. Run bash scripts/install-printing.sh first."
    exit 1
  fi
  mkdir -p /run/cups /var/cache/cups /var/log/cups
  if ! pgrep -x cupsd >/dev/null 2>&1; then
    /usr/sbin/cupsd
    sleep 1
  fi
  if lpstat -r 2>/dev/null | grep -q "scheduler is running"; then
    echo "CUPS scheduler is running. Open http://127.0.0.1:631 in the Debian browser."
  else
    echo "CUPS did not report a running scheduler. Check /var/log/cups/error_log."
    exit 1
  fi
'
