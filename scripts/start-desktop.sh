#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
command -v proot-distro >/dev/null || { echo "proot-distro is missing; run setup first." >&2; exit 1; }
command -v termux-x11 >/dev/null || { echo "Termux:X11 package is missing; run setup first." >&2; exit 1; }

export DISPLAY=:0
export PULSE_SERVER=127.0.0.1

if ! pgrep -f 'termux.x11' >/dev/null 2>&1; then
  termux-x11 :0 >/dev/null 2>&1 &
  sleep 2
fi

# XFCE session runs in the foreground. Keep this terminal open while using it.
proot-distro login debian --shared-tmp -- /bin/bash -lc '
  export DISPLAY=:0
  export PULSE_SERVER=127.0.0.1
  export XDG_RUNTIME_DIR=/tmp/runtime-root
  mkdir -p "$XDG_RUNTIME_DIR"
  chmod 700 "$XDG_RUNTIME_DIR"
  if pgrep -x xfce4-session >/dev/null 2>&1; then
    echo "An XFCE session already appears to be running."
    exit 0
  fi
  dbus-launch --exit-with-session startxfce4
'
