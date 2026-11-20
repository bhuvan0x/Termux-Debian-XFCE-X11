#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
run_script(){ bash "$ROOT/scripts/$1" "${@:2}"; }
usage(){ printf '%s\n' 'PrimeBook Workstation Suite' '  primebook-suite.sh health' '  primebook-suite.sh backup [backup|list|restore <archive>]' '  primebook-suite.sh maintenance [plan|apply]  (Debian root)' '  primebook-suite.sh tile {left|right|top|bottom|center|maximize}' '  primebook-suite.sh install-tools  (Debian root)'; }
case "${1:-}" in
 health) run_script primebook-health.sh ;;
 backup) shift; run_script primebook-restore.sh "${@:-backup}" ;;
 maintenance) shift; run_script primebook-maintenance.sh "${@:-plan}" ;;
 tile) shift; run_script primebook-tile.sh "$@" ;;
 install-tools)
  [ "$(id -u)" -eq 0 ] || { echo "Run inside Debian as root." >&2; exit 1; }
  export DEBIAN_FRONTEND=noninteractive; apt-get update
  apt-get install -y wmctrl x11-xserver-utils xclip xfce4-clipman-plugin tumbler ffmpegthumbnailer
  echo "Optional tools installed. Enable Clipman in XFCE Panel > Add New Items."
  ;;
 *) usage; exit 2;;
esac
