#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
proot-distro login debian -- /bin/bash -lc 'apt-get update && apt-get full-upgrade -y && apt-get autoremove -y && apt-get clean'
echo "Debian packages updated."
