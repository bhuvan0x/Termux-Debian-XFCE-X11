#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

command -v proot-distro >/dev/null 2>&1 || {
  echo "Run scripts/setup-termux.sh first." >&2
  exit 1
}

proot-distro login debian -- /bin/bash -s <<'DEBIAN_EPSON_CHECK'
set -u

echo "===== DEBIAN ARCHITECTURE ====="
dpkg --print-architecture

echo
echo "===== EPSON ESC/P-R DRIVER ====="
if dpkg-query -W -f='${Status} | version ${Version} | architecture ${Architecture}\n' printer-driver-escpr 2>/dev/null | grep -q '^install ok installed'; then
  dpkg-query -W -f='${Status} | version ${Version} | architecture ${Architecture}\n' printer-driver-escpr
else
  echo "NOT INSTALLED: run bash scripts/install-printing.sh from Termux."
fi

echo
echo "===== L3110 MODEL ENTRIES ====="
models="$(lpinfo -m 2>/dev/null | grep -i 'l3110' || true)"
if [ -n "$models" ]; then
  printf '%s\n' "$models"
else
  echo "No model entry was returned. Check that CUPS is running and inspect the available Epson entries:"
  lpinfo -m 2>/dev/null | grep -i 'epson' | head -n 20 || true
fi

echo
echo "===== CUPS SCHEDULER ====="
if lpstat -r 2>/dev/null; then
  :
else
  echo "CUPS is not responding. Start the workstation with start-all."
fi

echo
echo "===== CONFIGURED PRINTERS ====="
lpstat -p -d 2>&1 || true

echo
echo "===== USB PRINTER BACKENDS ====="
usb_backends="$(lpinfo -v 2>/dev/null | grep -iE 'usb|epson' || true)"
if [ -n "$usb_backends" ]; then
  printf '%s\n' "$usb_backends"
else
  echo "No USB printer backend is currently visible to CUPS."
fi

echo
echo "===== SCANNER DISCOVERY ====="
if command -v scanimage >/dev/null 2>&1; then
  scanimage -L 2>&1 || true
else
  echo "sane-utils is not installed."
fi

echo
echo "Reminder: the Epson L3110 is USB-only. A driver can be installed even when Android/PRoot does not expose the physical USB device."
DEBIAN_EPSON_CHECK
