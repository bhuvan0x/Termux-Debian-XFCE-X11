#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

command -v proot-distro >/dev/null || { echo "proot-distro is missing; run setup first." >&2; exit 1; }
command -v termux-x11 >/dev/null || { echo "Termux:X11 package is missing; run setup first." >&2; exit 1; }

export DISPLAY=:0

# Start and configure the Termux-side PulseAudio server through its local
# Unix socket. Do not export the Debian TCP PULSE_SERVER until this is done:
# otherwise host-side pactl would try the not-yet-loaded TCP bridge itself.
if command -v pulseaudio >/dev/null 2>&1 && command -v pactl >/dev/null 2>&1; then
  pulseaudio --start --exit-idle-time=-1 >/dev/null 2>&1 || true

  pulse_ready=0
  for ((attempt=0; attempt<15; attempt++)); do
    if env -u PULSE_SERVER pactl info >/dev/null 2>&1; then
      pulse_ready=1
      break
    fi
    sleep 1
  done

  if [ "$pulse_ready" -eq 1 ]; then
    module_id="$(env -u PULSE_SERVER pactl list short modules 2>/dev/null | awk '$2 == "module-native-protocol-tcp" { print $1; exit }' || true)"
    if [ -z "$module_id" ]; then
      if env -u PULSE_SERVER pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 >/dev/null 2>&1; then
        echo "PulseAudio TCP bridge loaded."
      else
        echo "Warning: could not load the PulseAudio TCP bridge."
      fi
    else
      echo "PulseAudio TCP bridge is already loaded (module $module_id)."
    fi

    tcp_ready=0
    for ((attempt=0; attempt<10; attempt++)); do
      if PULSE_SERVER=tcp:127.0.0.1 pactl info >/dev/null 2>&1; then
        tcp_ready=1
        break
      fi
      sleep 1
    done

    if [ "$tcp_ready" -eq 1 ]; then
      echo "PulseAudio TCP connection is ready for Debian."
    else
      echo "Warning: PulseAudio is running, but Debian's TCP audio connection is not responding."
    fi
  else
    echo "Warning: Termux PulseAudio did not become ready; desktop will start without confirmed audio."
  fi
fi

# Debian GUI applications connect to the host PulseAudio server over loopback.
export PULSE_SERVER=tcp:127.0.0.1

if ! pgrep -f 'termux.x11' >/dev/null 2>&1; then
  termux-x11 :0 >/dev/null 2>&1 &
  sleep 2
fi

if command -v am >/dev/null 2>&1; then
  am start -n com.termux.x11/.MainActivity >/dev/null 2>&1 || true
fi

proot-distro login --isolated debian -- /bin/bash -lc '
  if ! id prime >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash prime
  fi
  install -d -m 0700 -o prime -g prime /tmp/runtime-prime
'

# Start CUPS if the printing stack has been installed.
if proot-distro login --isolated debian -- test -x /usr/sbin/cupsd >/dev/null 2>&1; then
  bash "$SCRIPT_DIR/start-printing.sh" || echo "Warning: CUPS did not start; see docs/USB-AND-PRINTING.md."
fi

proot-distro login --isolated --shared-x11 --user prime debian -- /bin/bash -lc '
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
