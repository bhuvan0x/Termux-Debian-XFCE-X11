#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

if [ -z "${PREFIX:-}" ]; then
  echo "Run this script inside Termux." >&2
  exit 1
fi

echo "===== TERMUX SECURITY PRECHECK ====="
for command_name in pkg apt dpkg-query proot-distro; do
  command -v "$command_name" >/dev/null 2>&1 && echo "PASS: $command_name available" || echo "MISSING: $command_name"
done

PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
echo "proot-distro version: ${PD_VERSION:-not installed}"
if [ -n "$PD_VERSION" ] && dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "PASS: PRoot-Distro baseline is at least 5.8.0."
else
  echo "FAIL: Update proot-distro to 5.8.0 or newer before using isolated desktop sessions."
  echo "Run: pkg update && pkg upgrade -y && pkg install proot-distro"
fi

echo
echo "Termux HOME permissions:"
stat -c '%A %a %U:%G %n' "$HOME" 2>/dev/null || ls -ld "$HOME"
echo
echo "Termux package updates:"
apt list --upgradable 2>/dev/null | sed -n '1,80p' || true

echo
echo "Termux Android add-ons are separate apps. Check that Termux, Termux:X11, Termux:API and Termux:Widget come from mutually compatible signing sources."
