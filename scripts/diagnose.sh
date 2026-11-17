#!/data/data/com.termux/files/usr/bin/bash
set -u
printf '%s\n' '== Termux host =='
printf 'PREFIX=%s\n' "${PREFIX:-unknown}"
uname -a
for cmd in proot-distro termux-x11 pulseaudio termux-usb; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '%s: %s\n' "$cmd" "$(command -v "$cmd")"
  else
    printf '%s: missing\n' "$cmd"
  fi
done

printf '\n%s\n' '== Android USB inventory =='
if command -v termux-usb >/dev/null 2>&1; then
  termux-usb -l || true
else
  echo "termux-usb missing (install package termux-api and the Android add-on)."
fi

printf '\n%s\n' '== Debian distro =='
if command -v proot-distro >/dev/null 2>&1; then
  proot-distro list
  proot-distro login --isolated debian -- /bin/bash -lc '
    cat /etc/os-release 2>/dev/null
    echo
    dpkg -l xfce4 dbus-x11 cups printer-driver-escpr printer-driver-gutenprint usbutils xinput 2>/dev/null | tail -n +6
    echo
    echo "== VLC launch diagnostics =="
    if command -v vlc >/dev/null 2>&1; then
      printf "VLC command: %s\\n" "$(command -v vlc)"
      vlc --version 2>&1 | head -n 2 || true
    else
      echo "VLC command: missing"
    fi
    dpkg-query -W -f="${Status} ${Version}\\n" vlc vlc-plugin-qt 2>/dev/null || true
    for plugin_dir in /usr/lib/aarch64-linux-gnu/vlc/plugins/gui /usr/lib/aarch64-linux-gnu/vlc/plugins; do
      [ -d "$plugin_dir" ] && echo "VLC plugin directory: $plugin_dir"
    done
    if [ -f /home/prime/Documents/vlc-launch.log ]; then
      echo "Recent VLC launch log:"
      tail -n 25 /home/prime/Documents/vlc-launch.log
    else
      echo "No VLC launch log yet."
    fi

    echo
    if command -v lpstat >/dev/null 2>&1; then lpstat -r || true; fi
    if [ -d /dev/bus/usb ]; then echo "/dev/bus/usb: visible"; else echo "/dev/bus/usb: not exposed"; fi
  ' || true
fi

printf '\nDISPLAY=%s\n' "${DISPLAY:-unset}"
printf 'Termux:X11 process: '
pgrep -af 'termux.x11' || true
