#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Read-only Thunar rendering diagnostics. Run from Termux.
command -v proot-distro >/dev/null 2>&1 || {
  echo "proot-distro is missing." >&2
  exit 1
}
PD_VERSION="$(dpkg-query -W -f='${Version}' proot-distro 2>/dev/null || true)"
if [ -z "$PD_VERSION" ] || ! dpkg --compare-versions "$PD_VERSION" ge "5.8.0"; then
  echo "Update Termux proot-distro to version 5.8.0 or newer first." >&2
  exit 2
fi

proot-distro login --isolated --user prime debian -- /bin/bash -s <<'DEBIAN_SCRIPT'
set -u
OUT="$HOME/thunar-diagnostic.txt"
{
  echo "=== USER / SESSION ==="
  id
  printf 'HOME=%s DISPLAY=%s XDG_SESSION_TYPE=%s\n' "$HOME" "${DISPLAY:-}" "${XDG_SESSION_TYPE:-}"
  echo
  echo "=== RELEVANT PACKAGE VERSIONS ==="
  dpkg-query -W -f='${Package} ${Version} ${Status}\n' thunar libgtk-3-0 libpango-1.0-0 libpangocairo-1.0-0 fontconfig fonts-noto-core fonts-dejavu-core 2>&1
  echo
  echo "=== FONT MATCHING ==="
  command -v fc-match || true
  fc-match sans 2>&1
  fc-match 'Noto Sans' 2>&1
  fc-match 'DejaVu Sans' 2>&1
  echo
  echo "=== GTK SETTINGS ==="
  for f in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"; do
    echo "--- $f"
    if [ -f "$f" ]; then sed -n '1,220p' "$f"; else echo "(absent)"; fi
  done
  echo
  echo "=== XFCE GTK THEME / FONT ==="
  for p in /Net/ThemeName /Gtk/FontName /Gtk/MonospaceFontName; do
    xfconf-query -c xsettings -p "$p" 2>&1 || true
  done
  echo
  echo "=== THUNAR CONFIG ==="
  if [ -f "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml" ]; then
    sed -n '1,240p' "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml"
  else
    echo "(no thunar.xml)"
  fi
  echo
  echo "=== THUNAR VERSION / PROCESS ==="
  thunar --version 2>&1 || true
  pgrep -a thunar || true
  echo
  echo "=== FONT FILE SAMPLE ==="
  fc-list 2>/dev/null | head -n 12 || true
} > "$OUT" 2>&1

echo "Diagnostic report created: $OUT"
echo "Paste its contents with:"
cat "$OUT"
DEBIAN_SCRIPT
