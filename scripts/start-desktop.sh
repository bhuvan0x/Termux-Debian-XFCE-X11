#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

command -v proot-distro >/dev/null || { echo "proot-distro is missing; run setup first." >&2; exit 1; }
command -v termux-x11 >/dev/null || { echo "Termux:X11 package is missing; run setup first." >&2; exit 1; }

export DISPLAY=:0
export PULSE_SERVER=tcp:127.0.0.1

# Start the localhost-only PulseAudio TCP endpoint for Debian GUI apps.
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

# Ensure an unprivileged desktop account exists. VLC and browsers should not
# be run as root; install-apps.sh also creates this account and its shortcuts.
proot-distro login debian -- /bin/bash -lc '
  if ! id prime >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash prime
  fi
  install -d -m 0700 -o prime -g prime /tmp/runtime-prime
'

# Run the entire XFCE session as the normal user, not root.
proot-distro login debian --shared-tmp --user prime -- /bin/bash -lc '
  export DISPLAY=:0
  export PULSE_SERVER=tcp:127.0.0.1
  export XDG_RUNTIME_DIR=/tmp/runtime-prime
  mkdir -p "$XDG_RUNTIME_DIR"
  chmod 700 "$XDG_RUNTIME_DIR"

  if pgrep -x xfce4-session >/dev/null 2>&1; then
    echo "An XFCE session already appears to be running. Stop it first with scripts/stop-desktop.sh."
    exit 1
  fi

  dbus-launch --exit-with-session startxfce4
'
