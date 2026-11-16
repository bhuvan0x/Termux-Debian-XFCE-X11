#!/usr/bin/env bash
set -Eeuo pipefail

# Read-only XFCE/WhiteSur compatibility audit.
# Run as the Debian desktop user (normally: prime) inside the active XFCE session.
# This script does not install packages, write configuration, or start/stop services.

section() { printf '\n===== %s =====\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

section "IDENTITY AND OS"
printf 'User: %s\nHome: %s\n' "$(id -un)" "$HOME"
uname -a
if [ -r /etc/os-release ]; then
  sed -n '1,8p' /etc/os-release
fi
printf 'Architecture: '; dpkg --print-architecture 2>/dev/null || uname -m

section "XFCE COMPONENTS"
for pkg in xfce4-session xfce4-panel xfwm4 xfce4-settings xfdesktop4 xfce4-terminal; do
  if have dpkg-query; then
    dpkg-query -W -f='${binary:Package}\t${Version}\t${Status}\n' "$pkg" 2>/dev/null || true
  fi
done
for bin in xfce4-session xfce4-panel xfwm4 xfdesktop xfconf-query xfce4-terminal; do
  if have "$bin"; then
    printf '%s: ' "$bin"
    "$bin" --version 2>&1 | head -n 1 || true
  else
    printf '%s: not found\n' "$bin"
  fi
done

section "SESSION AND DISPLAY"
for name in DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS; do
  if [ -n "${!name-}" ]; then printf '%s=%s\n' "$name" "${!name}"; else printf '%s=(unset)\n' "$name"; fi
done
if have xrandr; then xrandr --current 2>&1 | sed -n '1,24p'; else echo "xrandr: not found"; fi
if have xdpyinfo; then xdpyinfo 2>/dev/null | grep -E 'dimensions:|resolution:' | head -n 2 || true; fi

section "GRAPHICS AND COMPOSITOR"
for bin in glxinfo eglinfo; do
  if have "$bin"; then
    printf '%s available\n' "$bin"
    if [ "$bin" = glxinfo ]; then "$bin" -B 2>&1 | sed -n '1,18p' || true; fi
  else
    printf '%s: not installed (not installing it)\n' "$bin"
  fi
done
if have xfconf-query; then
  for prop in /general/use_compositing /general/theme /general/title_font /general/button_layout; do
    printf '\nxfwm4 %s: ' "$prop"
    xfconf-query -c xfwm4 -p "$prop" 2>&1 || true
  done
fi

section "CURRENT XFCE APPEARANCE"
if have xfconf-query; then
  for pair in "xsettings:/Net/ThemeName" "xsettings:/Net/IconThemeName" "xsettings:/Gtk/CursorThemeName" "xsettings:/Gtk/FontName" "xfwm4:/general/theme"; do
    channel="${pair%%:*}"
    prop="${pair#*:}"
    printf '%s %s: ' "$channel" "$prop"
    xfconf-query -c "$channel" -p "$prop" 2>&1 || true
  done
else
  echo "xfconf-query unavailable; cannot read live XFCE settings."
fi

section "PANELS AND AUTOSTART"
if have xfconf-query; then
  xfconf-query -c xfce4-panel -lv 2>&1 | sed -n '1,160p' || true
fi
for dir in "$HOME/.config/autostart" /etc/xdg/autostart; do
  if [ -d "$dir" ]; then
    printf '\n%s\n' "$dir"
    find "$dir" -maxdepth 1 -type f -name '*.desktop' -printf '%f\n' 2>/dev/null | sort
  fi
done
printf '\nRelevant processes (if visible in this PRoot session):\n'
ps -eo pid,comm,args 2>/dev/null | grep -E '[x]fce4-panel|[x]fwm4|[x]fdesktop|[p]lank|[c]onky|[p]icom' || true

section "AVAILABLE COMPONENTS"
for bin in plank conky picom mpv; do
  if have "$bin"; then printf '%s: %s\n' "$bin" "$(command -v "$bin")"; else printf '%s: not installed\n' "$bin"; fi
done
if have dpkg-query; then
  for pattern in 'white*' 'papirus*' 'tela*' 'bibata*' 'arc-theme' 'adwaita-icon-theme'; do
    dpkg-query -W -f='${binary:Package}\t${Version}\n' "$pattern" 2>/dev/null || true
  done
fi

section "RESOURCES"
if have free; then free -h; fi
if have df; then df -h "$HOME" /tmp 2>/dev/null | awk '!seen[$0]++'; fi
if [ -r /proc/meminfo ]; then grep -E '^(MemTotal|MemAvailable|SwapTotal|SwapFree):' /proc/meminfo; fi
if [ -r /proc/cpuinfo ]; then
  grep -m 1 -E '^(model name|Processor|Hardware)' /proc/cpuinfo || true
fi

section "RELEVANT CONFIGURATION PATHS (METADATA ONLY)"
for path in \
  "$HOME/.config/xfce4" \
  "$HOME/.config/gtk-3.0" \
  "$HOME/.config/gtk-4.0" \
  "$HOME/.themes" \
  "$HOME/.icons" \
  "$HOME/.local/share/themes" \
  "$HOME/.local/share/icons" \
  "$HOME/.config/autostart"; do
  if [ -e "$path" ]; then
    stat -c '%A %U:%G %y %n' "$path" 2>/dev/null || true
    find "$path" -maxdepth 2 -type f -printf '  %p\n' 2>/dev/null | head -n 60
  else
    printf 'absent: %s\n' "$path"
  fi
done

section "AUDIT COMPLETE"
echo "Read-only audit finished. No packages, files, settings, or processes were changed."
