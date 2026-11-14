#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
usage() {
  cat <<'EOF'
Usage:
  bash scripts/check-usb.sh
  bash scripts/check-usb.sh --request /dev/bus/usb/001/002

Lists Android-visible USB devices. --request asks Android for permission
but does not create generic USB passthrough into Debian/PRoot.
EOF
}
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then usage; exit 0; fi
if ! command -v termux-usb >/dev/null 2>&1; then
  echo "termux-usb missing. Run: pkg install termux-api"
  echo "Install the separate Termux:API Android add-on from the same signing source:"
  echo "https://github.com/termux/termux-api"
  exit 1
fi

echo "== USB devices detected by Android / Termux:API =="
DEVICE_LIST="$(termux-usb -l)" || {
  echo "USB listing failed. Check the Termux:API add-on and USB OTG connection."
  exit 1
}
printf '%s\n' "$DEVICE_LIST"

if [ "${1:-}" = "--request" ]; then
  [ "$#" -eq 2 ] || { usage >&2; exit 2; }
  echo
  echo "Requesting Android permission for: $2"
  termux-usb -r "$2"
elif [ "$#" -gt 0 ]; then
  usage >&2
  exit 2
fi

echo
echo "== USB bus visibility inside Debian / PRoot =="
if command -v proot-distro >/dev/null 2>&1; then
  proot-distro login debian -- /bin/bash -lc '
    if command -v lsusb >/dev/null 2>&1; then lsusb || true
    else echo "usbutils not installed; run scripts/install-printing.sh."; fi
    if [ -d /dev/bus/usb ]; then
      echo "/dev/bus/usb exists in this Debian view."
    else
      echo "/dev/bus/usb is not exposed to this Debian PRoot environment."
    fi
    echo
    echo "SANE scanner discovery (L3110 USB ID: 04b8:1142; backend: epson2):"
    if command -v scanimage >/dev/null 2>&1; then scanimage -L || true
    else echo "scanimage missing; run scripts/install-printing.sh."; fi
  ' || true

  echo
  echo "== Input devices visible through the active X11 display =="
  if pgrep -f 'termux.x11' >/dev/null 2>&1; then
    proot-distro login debian -- /usr/bin/env DISPLAY=:0 /bin/bash -lc '
      if command -v xinput >/dev/null 2>&1; then xinput list || true
      else echo "xinput is not installed. Run scripts/install-apps.sh."; fi
    ' || true
  else
    echo "X11 does not appear to be running. Open Termux:X11 and start the desktop, then retry."
  fi
else
  echo "proot-distro is not installed."
fi

cat <<'EOF'

How to interpret this:
- Android USB detection confirms Android can see the attached device.
- USB keyboards/mice/HID devices normally enter through Android's input stack;
  Termux:X11 can receive mapped input events when its window has focus.
  XInput above lists devices exposed by the running X server.
- Android termux-usb can pass a USB file descriptor to a specially written
  Termux program. It does not expose arbitrary USB devices as normal
  /dev/bus/usb nodes inside Debian/PRoot.
- A permission grant is not proof that CUPS, SANE or a Debian USB driver can
  operate the device.
- USB storage is normally mounted/authorized by Android and accessed through
  shared storage, not mounted directly by Debian.
- Epson L3110 is USB-only (no built-in network interface). A separate USB print
  server/host is needed to share it over the network when PRoot cannot access USB.
  See docs/USB-AND-PRINTING.md.
EOF
