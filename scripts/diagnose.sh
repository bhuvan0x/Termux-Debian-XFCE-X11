#!/data/data/com.termux/files/usr/bin/bash
set -u
printf '%s\n' '== Termux host =='
printf 'PREFIX=%s\n' "${PREFIX:-unknown}"
uname -a
for cmd in proot-distro termux-x11 pulseaudio; do
  if command -v "$cmd" >/dev/null 2>&1; then printf '%s: %s\n' "$cmd" "$(command -v "$cmd")"; else printf '%s: missing\n' "$cmd"; fi
done
printf '\n%s\n' '== Debian distro =='
if command -v proot-distro >/dev/null 2>&1; then
  proot-distro list
  proot-distro login debian -- /bin/bash -lc 'cat /etc/os-release 2>/dev/null; echo; dpkg -l xfce4 dbus-x11 2>/dev/null | tail -n +6'
fi
printf '\nDISPLAY=%s\n' "${DISPLAY:-unset}"
printf 'Termux:X11 process: '
pgrep -af 'termux.x11' || true
