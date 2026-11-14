#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Stop XFCE components by exact process name. This also clears an older
# root-owned session created by previous versions of this project.
proot-distro login debian -- /bin/bash -lc '
  for process in xfce4-session xfwm4 xfce4-panel xfdesktop; do
    pkill -TERM -x "$process" 2>/dev/null || true
  done
'

echo "XFCE stop signal sent. Close the Termux:X11 app when finished."
