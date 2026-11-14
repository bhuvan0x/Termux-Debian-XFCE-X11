#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
usage() {
  cat <<'EOF'
Usage:
  bash scripts/check-usb.sh
  bash scripts/check-usb.sh --request /dev/bus/usb/001/002

Lists USB devices visible to Android. --request asks Android for permission
to access one device through Termux:API. It does not create generic USB
passthrough into Debian/PRoot.
EOF
}
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then usage; exit 0; fi
if ! command -v termux-usb >/dev/null 2>&1; then
  echo "termux-usb is missing. Install its Termux client package with: pkg install termux-api"
  echo "Also install the separate Termux:API Android add-on from the same signing source:"
  echo "https://github.com/termux/termux-api"
  exit 1
fi

echo "== USB devices detected by Android / Termux:API =="
DEVICE_LIST="$(termux-usb -l)" || {
  echo "USB listing failed. Check that the Termux:API Android add-on is installed and opened once."
  exit 1
}
printf '%s\n' "$DEVICE_LIST"

if [ "${1:-}" = "--request" ]; then
  [ "$#" -eq 2 ] || { usage >&2; exit 2; }
  echo
  echo "Requesting Android USB permission for: $2"
  termux-usb -r "$2"
elif [ "$#" -gt 0 ]; then usage >&2; exit 2; fi

echo
echo "== Debian / PRoot USB visibility =="
if command -v proot-distro >/dev/null 2>&1; then
  proot-distro login debian -- /bin/bash -lc '
    if command -v lsusb >/dev/null 2>&1; then lsusb || true
    else echo "usbutils not installed; run scripts/install-printing.sh."; fi
  ' || true
else echo "proot-distro is not installed."; fi

cat <<'EOF'

Important:
- Android/Termux:API can enumerate USB devices and grant an app a file
  descriptor after user approval. It does not expose arbitrary USB devices
  directly as /dev/bus/usb nodes to every Linux process.
- This check confirms Android detection; it does not prove that CUPS, scanners
  or arbitrary Debian USB drivers can operate the device.
- USB keyboards/mice are normally handled by Android input and delivered to
  the foreground X11 app. USB storage must be mounted/authorized by Android
  and exposed through shared storage.
- For an Epson printer, Wi-Fi/Ethernet printing through CUPS is the reliable
  route in this PRoot setup. See docs/USB-AND-PRINTING.md.
EOF
