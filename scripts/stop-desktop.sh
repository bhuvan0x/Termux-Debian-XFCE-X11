#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Stop only the XFCE processes belonging to the dedicated Debian desktop user.
proot-distro login debian -- /bin/bash -lc '
  pkill -TERM -u prime -x xfce4-session 2>/dev/null || true
  pkill -TERM -u prime -x xfwm4 2>/dev/null || true
  pkill -TERM -u prime -x xfce4-panel 2>/dev/null || true
  pkill -TERM -u prime -x xfdesktop 2>/dev/null || true
'

echo "XFCE stop signal sent. Close the Termux:X11 app when finished."
