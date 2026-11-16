#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Run from Termux while the Debian XFCE desktop is open in Termux:X11.
# Fresco is removed only after the user confirms that lowpaper is visibly working.

command -v proot-distro >/dev/null 2>&1 || {
  echo "proot-distro is missing. Run scripts/setup-termux.sh first." >&2
  exit 1
}

proot-distro login --isolated --shared-x11 debian -- /bin/bash -s <<'DEBIAN_SCRIPT'
set -Eeuo pipefail

die() {
  printf 'Wallpaper migration stopped: %s\n' "$*" >&2
  exit 1
}

PRIME_HOME="$(getent passwd prime | cut -d: -f6)"
[ -n "$PRIME_HOME" ] && [ -d "$PRIME_HOME" ] || die "Debian user prime was not found."

# PRoot's isolated process view cannot reliably see the XFCE processes
# launched by start-desktop.sh. Validate the live X11 and D-Bus endpoints
# instead of searching /proc or relying on pgrep across PRoot sessions.
DISPLAY_VALUE=":0.0"
RUNTIME_DIR="/tmp/runtime-prime"
[ -d "$RUNTIME_DIR" ] || die "The XFCE runtime directory $RUNTIME_DIR is missing."

as_prime_with_bus() {
  local bus="$1"
  shift
  runuser -u prime -- env \
    "HOME=$PRIME_HOME" "USER=prime" "LOGNAME=prime" \
    "DISPLAY=$DISPLAY_VALUE" "XDG_RUNTIME_DIR=$RUNTIME_DIR" \
    "XDG_SESSION_TYPE=x11" "XDG_CURRENT_DESKTOP=XFCE" \
    "DBUS_SESSION_BUS_ADDRESS=$bus" \
    "PATH=$PRIME_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin" "$@"
}

DBUS_BUS=""
for bus_socket in /tmp/dbus-*; do
  [ -S "$bus_socket" ] || continue
  candidate_bus="unix:path=$bus_socket"
  if as_prime_with_bus "$candidate_bus" xfconf-query -c xfwm4 -p /general/use_compositing >/dev/null 2>&1; then
    DBUS_BUS="$candidate_bus"
    break
  fi
done
[ -n "$DBUS_BUS" ] || die "Could not connect to the active XFCE D-Bus session. Keep the desktop open and retry."

PRIME_ENV=(
  "HOME=$PRIME_HOME"
  "USER=prime"
  "LOGNAME=prime"
  "DISPLAY=$DISPLAY_VALUE"
  "XDG_RUNTIME_DIR=$RUNTIME_DIR"
  "XDG_SESSION_TYPE=x11"
  "XDG_CURRENT_DESKTOP=XFCE"
  "DBUS_SESSION_BUS_ADDRESS=$DBUS_BUS"
  "PATH=$PRIME_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
)

as_prime() {
  runuser -u prime -- env "${PRIME_ENV[@]}" "$@"
}

as_prime xrandr --listmonitors | grep -q 'Monitors:' || die "Termux:X11 has no active X11 monitor."
ORIGINAL_COMPOSITING="$(as_prime xfconf-query -c xfwm4 -p /general/use_compositing 2>/dev/null)" ||
  die "Could not read the XFCE compositor setting."
case "$ORIGINAL_COMPOSITING" in
  true|false) ;;
  *) die "Unexpected XFCE compositor setting: $ORIGINAL_COMPOSITING" ;;
esac

MIGRATION_CONFIRMED=0
LOWPAPER_STARTED=0
LOWPAPER="$PRIME_HOME/.local/bin/lowpaper"
restore_unconfirmed_state() {
  local result=$?
  trap - EXIT
  if [ "$MIGRATION_CONFIRMED" -ne 1 ]; then
    if [ "$LOWPAPER_STARTED" -eq 1 ]; then
      as_prime "$LOWPAPER" stop >/dev/null 2>&1 || true
    fi
    if [ "$ORIGINAL_COMPOSITING" = false ]; then
      as_prime xfconf-query -c xfwm4 -p /general/use_compositing --set false >/dev/null 2>&1 || true
    fi
  fi
  exit "$result"
}
trap restore_unconfirmed_state EXIT

# lowpaper's XFCE icon overlay needs the compositor. Preserve the user's
# original setting and restore it automatically if migration is declined/fails.
if [ "$ORIGINAL_COMPOSITING" = false ]; then
  as_prime xfconf-query -c xfwm4 -p /general/use_compositing --set true ||
    die "Could not enable XFCE compositing for lowpaper's icon overlay."
fi
[ "$(as_prime xfconf-query -c xfwm4 -p /general/use_compositing)" = true ] ||
  die "XFCE compositing did not enable successfully."

for command_name in mpv python3 xprop xrandr xkill xwininfo xev xset gcc curl sha256sum ffprobe xfconf-query; do
  command -v "$command_name" >/dev/null 2>&1 || die "Missing dependency: $command_name"
done

WALLPAPER="$PRIME_HOME/Videos/Wallpapers/Alisa-Live-Wallpaper.mp4"
ORIGINAL_WALLPAPER="$PRIME_HOME/.local/share/fresco/library/downloads/Alisa_Mikhailovna_Kujou_Live_Wallpaper-617837642703943076.mp4"
if [ ! -s "$WALLPAPER" ] && [ -s "$ORIGINAL_WALLPAPER" ]; then
  install -d -o prime -g prime "$PRIME_HOME/Videos/Wallpapers"
  cp -p "$ORIGINAL_WALLPAPER" "$WALLPAPER"
  chown prime:prime "$WALLPAPER"
fi
[ -s "$WALLPAPER" ] || die "The preserved Alisa wallpaper is missing at $WALLPAPER."
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$WALLPAPER" >/dev/null ||
  die "The preserved wallpaper is not a readable video."

for binary in /usr/local/bin/fresco /usr/local/bin/frescod; do
  if [ -e "$binary" ]; then
    owner="$(dpkg-query -S "$binary" 2>/dev/null || true)"
    [ -z "$owner" ] || die "$binary is owned by a Debian package ($owner); refusing to remove package-managed files."
  fi
done

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$PRIME_HOME/Documents/Wallpaper-Migration-Backup-$STAMP"
install -d -m 0700 -o prime -g prime "$BACKUP"
printf '%s\n' "$WALLPAPER" > "$BACKUP/preserved-wallpaper-path.txt"
chown prime:prime "$BACKUP/preserved-wallpaper-path.txt"

LOWPAPER_CONFIG="$PRIME_HOME/.config/lowpaper"
if [ -e "$LOWPAPER" ]; then
  cp -a "$LOWPAPER" "$BACKUP/previous-lowpaper"
fi
if [ -d "$LOWPAPER_CONFIG" ]; then
  cp -a "$LOWPAPER_CONFIG" "$BACKUP/previous-lowpaper-config"
fi
TMP="$(mktemp)"
trap 'rm -f "$TMP"; restore_unconfirmed_state' EXIT
LOWPAPER_URL="https://github.com/Meinianda-L/lowpaper/releases/download/v0.1.1/lowpaper"
EXPECTED_SHA256="f2596b647c1d7241264712c5027a7644b6b9b0d7166f6b91691f62236c198d25"
curl -fL --retry 3 --connect-timeout 20 "$LOWPAPER_URL" -o "$TMP"
printf '%s  %s\n' "$EXPECTED_SHA256" "$TMP" | sha256sum -c - >/dev/null ||
  die "lowpaper v0.1.1 checksum verification failed."

python3 - "$TMP" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

old_launch = 'setsid mpv "${opts[@]}" --vo=xv,gpu,x11 --wid="$wid" --input-ipc-server="$sock" "$@"'
new_launch = 'setsid mpv "${opts[@]}" --vo=gpu --gpu-api=opengl --gpu-context=x11egl --wid="$wid" --input-ipc-server="$sock" "$@"'

if text.count("set -u\n") != 1:
    raise SystemExit("Unexpected lowpaper header; refusing to patch an unknown script.")
if text.count(old_launch) != 1:
    raise SystemExit("Unexpected lowpaper X11 MPV launch line; refusing to patch an unknown script.")

text = text.replace(
    "set -u\n",
    "set -u\nexport LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe\n",
    1,
)
text = text.replace(old_launch, new_launch, 1)
path.write_text(text, encoding="utf-8")
PY

bash -n "$TMP" || die "Patched lowpaper script failed Bash syntax validation."
install -d -m 0755 -o prime -g prime "$PRIME_HOME/.local/bin"
install -o prime -g prime -m 0755 "$TMP" "$LOWPAPER"

install -d -m 0755 -o prime -g prime "$LOWPAPER_CONFIG"
cat > "$LOWPAPER_CONFIG/config" <<'LOWPAPER_CONFIG_EOF'
FIT=fill
INTERVAL=300
SHUFFLE=0
AUDIO=0
AUTOPAUSE=1
HWDEC=no
CACHE_MB=0
ICONS=1
LOWPAPER_CONFIG_EOF
chown prime:prime "$LOWPAPER_CONFIG/config"
chmod 0600 "$LOWPAPER_CONFIG/config"

echo
echo "Starting lowpaper with the verified software-rendering path..."
as_prime "$LOWPAPER" "$WALLPAPER"
LOWPAPER_STARTED=1
sleep 4
STATUS="$(as_prime "$LOWPAPER" status 2>&1 || true)"
printf '%s\n' "$STATUS"
if ! grep -q 'playing' <<< "$STATUS"; then
  as_prime "$LOWPAPER" stop >/dev/null 2>&1 || true
  die "MPV did not report active playback. Fresco has NOT been removed. Check /tmp/runtime-prime/lowpaper-$(id -u prime)/<monitor-name>.log and retry after diagnosis."
fi

echo
echo "VISUAL CHECK REQUIRED"
echo "Look at the XFCE desktop now:"
echo "  1. Is the Alisa video visible (not a black desktop)?"
echo "  2. Are your desktop icons still visible and clickable?"
echo
answer=""
if ! read -r -p "If BOTH are working, type YES to enable lowpaper at login and remove Fresco: " answer </dev/tty; then
  as_prime "$LOWPAPER" stop >/dev/null 2>&1 || true
  die "No confirmation was received. Fresco was left installed."
fi
if [ "$answer" != YES ]; then
  as_prime "$LOWPAPER" stop >/dev/null 2>&1 || true
  echo "Lowpaper was stopped. Fresco, its configuration and its library were left untouched."
  echo "The wallpaper remains at: $WALLPAPER"
  exit 0
fi

as_prime "$LOWPAPER" startup on
[ -s "$PRIME_HOME/.config/autostart/lowpaper.desktop" ] ||
  die "Could not verify lowpaper autostart. Fresco has NOT been removed."

move_to_backup() {
  local source_path="$1"
  local backup_path="$2"
  if [ -e "$source_path" ] || [ -L "$source_path" ]; then
    install -d -m 0700 -o prime -g prime "$(dirname "$backup_path")"
    mv -- "$source_path" "$backup_path"
  fi
}

# Stop Fresco through its documented control socket. The isolated PRoot
# process table cannot reliably see or signal the daemon launched by XFCE.
FRESCO_SOCKET="$RUNTIME_DIR/fresco/control.sock"
if [ -S "$FRESCO_SOCKET" ]; then
  echo "Stopping Fresco through its control socket..."
  as_prime python3 - "$FRESCO_SOCKET" <<'PY'
import socket
import sys

sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.settimeout(8)
try:
    sock.connect(sys.argv[1])
    sock.sendall(b'{"cmd":"stop"}\\n')
    response = b""
    while b"\\n" not in response and len(response) < 65536:
        chunk = sock.recv(4096)
        if not chunk:
            break
        response += chunk
    if not response:
        raise SystemExit("Fresco control socket returned no response to stop.")
    print("Fresco stop response:", response.decode("utf-8", "replace").strip())
finally:
    sock.close()
PY
  stopped=0
  for attempt in $(seq 1 20); do
    if [ ! -S "$FRESCO_SOCKET" ]; then
      stopped=1
      break
    fi
    sleep 0.5
  done
  [ "$stopped" -eq 1 ] || die "Fresco did not release its control socket after the stop request. Its files have NOT been archived or removed."
else
  echo "No active Fresco control socket found; continuing with Fresco data archival."
fi

move_to_backup "$PRIME_HOME/.config/fresco" "$BACKUP/fresco-user/config"
move_to_backup "$PRIME_HOME/.local/state/fresco" "$BACKUP/fresco-user/state"
move_to_backup "$PRIME_HOME/.local/share/fresco" "$BACKUP/fresco-user/library"
move_to_backup "$PRIME_HOME/.cache/fresco" "$BACKUP/fresco-user/cache"
move_to_backup "$PRIME_HOME/.local/share/applications/fresco.desktop" "$BACKUP/fresco-launchers/user-applications-fresco.desktop"
move_to_backup "$PRIME_HOME/.config/autostart/fresco.desktop" "$BACKUP/fresco-launchers/user-autostart-fresco.desktop"
move_to_backup "/usr/share/applications/fresco.desktop" "$BACKUP/fresco-launchers/system-applications-fresco.desktop"
move_to_backup "/etc/xdg/autostart/fresco.desktop" "$BACKUP/fresco-launchers/system-autostart-fresco.desktop"
move_to_backup "/usr/local/share/fresco" "$BACKUP/fresco-system-share"

for binary in /usr/local/bin/fresco /usr/local/bin/frescod; do
  if [ -e "$binary" ] || [ -L "$binary" ]; then
    install -d -m 0700 -o prime -g prime "$BACKUP/fresco-system-binaries"
    cp -a "$binary" "$BACKUP/fresco-system-binaries/"
    rm -f -- "$binary"
  fi
done

SOURCE_TREE="$PRIME_HOME/src/Fresco"
if [ -d "$SOURCE_TREE" ]; then
  if [ -f "$SOURCE_TREE/Cargo.toml" ] && grep -qiE '^name[[:space:]]*=[[:space:]]*"fresco"' "$SOURCE_TREE/Cargo.toml"; then
    move_to_backup "$SOURCE_TREE" "$BACKUP/fresco-source-tree"
    echo "Archived the verified Fresco source/build tree at $BACKUP/fresco-source-tree."
  else
    echo "Skipped $SOURCE_TREE because it did not match the expected Fresco Cargo project."
  fi
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  as_prime update-desktop-database "$PRIME_HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

[ ! -e /usr/local/bin/fresco ] && [ ! -e /usr/local/bin/frescod ] ||
  die "A Fresco executable remains in /usr/local/bin."

echo
echo "Migration complete."
echo "Wallpaper: $WALLPAPER"
echo "lowpaper:  $LOWPAPER"
echo "Backup:    $BACKUP"
echo
echo "Useful commands (run inside Debian as prime):"
echo "  lowpaper status"
echo "  lowpaper pause"
echo "  lowpaper resume"
echo "  lowpaper stop"
echo "  lowpaper startup off"
echo
echo "Fresco user settings, state, library and launchers were archived in the backup directory."
DEBIAN_SCRIPT
