#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Stop the Debian desktop session without killing unrelated Termux processes.
proot-distro login debian -- /bin/bash -lc 'pkill -TERM -x xfce4-session 2>/dev/null || true; pkill -TERM -x xfwm4 2>/dev/null || true; pkill -TERM -x xfce4-panel 2>/dev/null || true'

# Termux:X11 server can be closed separately from its Android app if desired.
echo "XFCE stop signal sent. Close the Termux:X11 app when finished."
