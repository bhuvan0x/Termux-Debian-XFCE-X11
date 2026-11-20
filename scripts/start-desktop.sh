#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

command -v proot-distro >/dev/null || { echo "proot-distro is missing; run setup first." >&2; exit 1; }
command -v termux-x11 >/dev/null || { echo "Termux:X11 package is missing; run setup first." >&2; exit 1; }

PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Security stop: update Termux proot-distro to 5.8.0 or newer:" >&2
  echo "  pkg update && pkg upgrade -y" >&2
  exit 2
fi

# Refuse to launch a partial XFCE session. A previous apt autoremove may have
# removed components while leaving desktop launchers and user configuration.
if ! proot-distro login --isolated debian -- /bin/bash -lc '
  missing=()
  for binary in startxfce4 xfwm4 xfdesktop xfce4-panel xfce4-terminal thunar dbus-launch; do
    command -v "$binary" >/dev/null 2>&1 || missing+=("$binary")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    printf "Missing Debian desktop components: %s\\n" "${missing[*]}" >&2
    exit 1
  fi
'; then
  echo "Debian desktop is incomplete. Repair it from Termux with:" >&2
  echo "  bash \"$SCRIPT_DIR/repair-desktop.sh\"" >&2
  exit 4
fi

export DISPLAY=:0

# Expose only Android's Downloads directory to the isolated Debian desktop.
# termux-setup-storage must have been run and Android storage permission granted.
DOWNLOADS_DIR="$HOME/storage/downloads"
if [ ! -d "$DOWNLOADS_DIR" ]; then
  echo "Android Downloads is not available to Termux."
  echo "Run: termux-setup-storage"
  echo "Grant the requested Android storage permission, then run start-all again."
  exit 3
fi
DOWNLOADS_DIR="$(realpath "$DOWNLOADS_DIR")"
echo "Android Downloads will be available in Debian at /mnt/android-downloads"

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
  install -d -m 0755 /mnt/android-downloads
  install -d -m 0755 -o prime -g prime /home/prime/.config/gtk-3.0
  BOOKMARKS=/home/prime/.config/gtk-3.0/bookmarks
  touch "$BOOKMARKS"
  chown prime:prime "$BOOKMARKS"
  if ! grep -Fq "file:///mnt/android-downloads" "$BOOKMARKS"; then
    printf "%s\n" "file:///mnt/android-downloads PrimeBook Downloads" >> "$BOOKMARKS"
    chown prime:prime "$BOOKMARKS"
  fi
'

# Start CUPS if the printing stack has been installed.
if proot-distro login --isolated debian -- test -x /usr/sbin/cupsd >/dev/null 2>&1; then
  bash "$SCRIPT_DIR/start-printing.sh" || echo "Warning: CUPS did not start; see docs/USB-AND-PRINTING.md."
fi

# Keep the system D-Bus daemon alive in the same root PRoot session as
# XFCE. Starting it in a separate proot-distro login would leave a stale
# socket when that isolated session exits (the exact GNOME Software failure).
# The GUI itself still runs as the unprivileged prime user.
proot-distro login --isolated --shared-x11 --bind "$DOWNLOADS_DIR:/mnt/android-downloads" debian -- /bin/bash -lc '
  set -Eeuo pipefail
  install -d -m 0755 /run/dbus
  rm -f /run/dbus/system_bus_socket
  dbus-daemon --system --nofork --nopidfile &
  SYSTEM_DBUS_PID=$!
  cleanup_system_bus() {
    kill "$SYSTEM_DBUS_PID" 2>/dev/null || true
    wait "$SYSTEM_DBUS_PID" 2>/dev/null || true
    rm -f /run/dbus/system_bus_socket
  }
  trap cleanup_system_bus EXIT INT TERM

  bus_ready=0
  for attempt in $(seq 1 10); do
    if dbus-send --system --print-reply --dest=org.freedesktop.DBus \
      /org/freedesktop/DBus org.freedesktop.DBus.ListNames >/dev/null 2>&1; then
      bus_ready=1
      break
    fi
    sleep 1
  done
  if [ "$bus_ready" -eq 1 ]; then
    echo "Debian system D-Bus is ready for PackageKit/Discover."
  else
    echo "WARNING: system D-Bus did not become ready; XFCE will still start."
    echo "Discover will log the unavailable service in ~/Documents/discover.log."
  fi

  if pgrep -x xfce4-session >/dev/null 2>&1; then
    echo "An XFCE session already appears to be running. Stop it first."
    exit 1
  fi

  install -d -m 0700 -o prime -g prime /tmp/runtime-prime
  # Clear saved application snapshots; keep persistent Xfconf desktop appearance.
  install -d -m 0700 -o prime -g prime /home/prime/.cache/sessions
  find /home/prime/.cache/sessions -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +

  # Use Debian verified absolute runuser path; command lookup through
  # login shells has been unreliable in this isolated PRoot environment.
  # Disable future application-session snapshots without changing the Xfconf
  # persistent desktop appearance settings.
  /usr/sbin/runuser -u prime -- env \
    HOME=/home/prime USER=prime LOGNAME=prime \
    DISPLAY=:0 \
    PULSE_SERVER=tcp:127.0.0.1 \
    XDG_RUNTIME_DIR=/tmp/runtime-prime \
    XDG_SESSION_TYPE=x11 \
    dbus-launch --exit-with-session xfconf-query --create \
      -c xfce4-session -p /general/SaveOnExit -t bool -s false

  # Run XFCE as the unprivileged desktop user. Keep this foreground process
  # inside the same shared-X11 PRoot session as the system D-Bus daemon.
  /usr/sbin/runuser -u prime -- env \
    HOME=/home/prime USER=prime LOGNAME=prime \
    DISPLAY=:0 \
    PULSE_SERVER=tcp:127.0.0.1 \
    XDG_RUNTIME_DIR=/tmp/runtime-prime \
    XDG_SESSION_TYPE=x11 \
    dbus-launch --exit-with-session startxfce4
'
