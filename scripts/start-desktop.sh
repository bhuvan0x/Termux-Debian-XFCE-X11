#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

command -v proot-distro >/dev/null || { echo "proot-distro is missing; run setup first." >&2; exit 1; }
command -v termux-x11 >/dev/null || { echo "Termux:X11 package is missing; run setup first." >&2; exit 1; }

export DISPLAY=:0
export PULSE_SERVER=tcp:127.0.0.1

if command -v pulseaudio >/dev/null 2>&1; then
  pulseaudio --start --exit-idle-time=-1 >/dev/null 2>&1 || true
  if command -v pactl >/dev/null 2>&1; then
    pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 >/dev/null 2>&1 || true
  fi
fi

if ! pgrep -f 'termux.x11' >/dev/null 2>&1; then
  termux-x11 :0 >/dev/null 2>&1 &
  sleep 2
fi

if command -v am >/dev/null 2>&1; then
  am start -n com.termux.x11/.MainActivity >/dev/null 2>&1 || true
fi

proot-distro login debian -- /bin/bash -lc '
  if ! id prime >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash prime
  fi
  install -d -m 0700 -o prime -g prime /tmp/runtime-prime
'

# Start CUPS if the printing stack has been installed.
if proot-distro login debian -- test -x /usr/sbin/cupsd >/dev/null 2>&1; then
  bash "$SCRIPT_DIR/start-printing.sh" || echo "Warning: CUPS did not start; see docs/USB-AND-PRINTING.md."
fi

proot-distro login debian --shared-tmp --user prime -- /bin/bash -lc '
  export DISPLAY=:0
  export PULSE_SERVER=tcp:127.0.0.1
  export XDG_RUNTIME_DIR=/tmp/runtime-prime
  export XDG_SESSION_TYPE=x11
  mkdir -p "$XDG_RUNTIME_DIR"
  chmod 700 "$XDG_RUNTIME_DIR"

  if pgrep -x xfce4-session >/dev/null 2>&1; then
    echo "An XFCE session already appears to be running. Stop it first."
    exit 1
  fi

  dbus-launch --exit-with-session startxfce4
'
