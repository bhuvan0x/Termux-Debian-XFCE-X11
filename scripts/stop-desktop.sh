#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Stop the standalone clock before XFCE so it cannot remain as an orphaned
# X11 window after the desktop session is stopped.
proot-distro login --isolated debian -- /bin/bash -lc '
  pkill -u prime -f "[q]ml6 /home/prime/.local/share/modern-gaming-clock/main.qml" 2>/dev/null || true
'

# Stop XFCE components by exact process name. This also clears an older
# root-owned session created by previous versions of this project.
proot-distro login --isolated debian -- /bin/bash -lc '
  for process in xfce4-session xfwm4 xfce4-panel xfdesktop; do
    pkill -TERM -x "$process" 2>/dev/null || true
  done
'

echo "XFCE stop signal sent. Close the Termux:X11 app when finished."
