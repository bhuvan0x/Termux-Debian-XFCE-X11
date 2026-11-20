#!/usr/bin/env bash
set -Eeuo pipefail
ACTION="${1:-}"
case "$ACTION" in left|right|top|bottom|maximize|center) ;; *) echo "Usage: $0 {left|right|top|bottom|center|maximize}" >&2; exit 2;; esac
for c in wmctrl xrandr; do command -v "$c" >/dev/null 2>&1 || { echo "Missing $c; install wmctrl and x11-xserver-utils." >&2; exit 1; }; done
geometry="$(xrandr --current | awk '/ connected/ && match($0,/[0-9]+x[0-9]+[+-][0-9]+[+-][0-9]+/) {print substr($0,RSTART,RLENGTH); exit}')"
[ -n "$geometry" ] || { echo "Cannot detect X11 output geometry." >&2; exit 1; }
read -r w h x y < <(sed -E 's/^([0-9]+)x([0-9]+)([+-][0-9]+)([+-][0-9]+)$/\1 \2 \3 \4/' <<<"$geometry")
w=$((w)); h=$((h)); x=$((x)); y=$((y)); hw=$((w/2)); hh=$((h/2))
case "$ACTION" in
 left) args="0,$x,$y,$hw,$h";; right) args="0,$((x+hw)),$y,$((w-hw)),$h";;
 top) args="0,$x,$y,$w,$hh";; bottom) args="0,$x,$((y+hh)),$w,$((h-hh))";;
 maximize) wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz; exit;;
 center) args="0,$((x+w/10)),$((y+h/10)),$((w*8/10)),$((h*8/10))";;
esac
wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz
wmctrl -r :ACTIVE: -e "$args"
