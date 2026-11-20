#!/usr/bin/env bash
set -Eeuo pipefail
section(){ printf '\n== %s ==\n' "$1"; }
have(){ command -v "$1" >/dev/null 2>&1; }
section "SYSTEM"
printf 'User: %s\nHost: %s\nArchitecture: %s\nKernel: %s (Android host)\n' "$(id -un)" "$(hostname)" "$(dpkg --print-architecture 2>/dev/null || uname -m)" "$(uname -r)"
printf 'Desktop: %s | Display: %s\n' "${XDG_CURRENT_DESKTOP:-unknown}" "${DISPLAY:-unset}"
uptime -p 2>/dev/null || uptime
section "MEMORY"
if have free; then free -h; else grep -E '^(MemTotal|MemAvailable|SwapTotal|SwapFree):' /proc/meminfo; fi
section "STORAGE"
df -h "$HOME" /tmp 2>/dev/null | awk '!seen[$1 FS $6]++'
[ -d /mnt/android-downloads ] && echo "Android Downloads mount: present" || echo "Android Downloads mount: not detected"
section "DESKTOP"
for p in xfce4-session xfwm4 xfce4-panel plank xfce4-notifyd; do pgrep -x "$p" >/dev/null 2>&1 && echo "RUNNING $p" || echo "STOPPED $p"; done
section "PACKAGE HEALTH"
if have apt-get; then apt-get check 2>&1 || true; printf 'Upgradable packages: '; apt list --upgradable 2>/dev/null | awk 'NR>1{n++} END{print n+0}'; fi
section "OPTIONAL TOOLS"
for c in wmctrl xdotool xrandr xclip yad rofi tumbler ffmpegthumbnailer; do have "$c" && echo "AVAILABLE $c" || echo "MISSING $c"; done
section "BOUNDARIES"
echo "PRoot shares the Android kernel. Host battery, radios and notification data require Android-side Termux:API permissions."
