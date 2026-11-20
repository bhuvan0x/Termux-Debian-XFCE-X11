#!/usr/bin/env bash
# GNOME-inspired application and workflow layer for XFCE in Debian/PRoot.
set -Eeuo pipefail

ACTION="${1:-help}"
PACKAGES=(
  adwaita-icon-theme
  gnome-themes-extra
  gnome-calculator
  gnome-text-editor
  loupe
  evince
  file-roller
  gnome-system-monitor
  gnome-font-viewer
  dconf-editor
  rofi
  xfce4-notifyd
)

usage() {
  cat <<'EOF'
PrimeBook GNOME Core for XFCE
  sudo bash scripts/primebook-gnome-core.sh install
      Install GNOME-style applications, Adwaita assets and Rofi.
  bash scripts/primebook-gnome-core.sh theme
      Back up current XFCE appearance settings, then apply Adwaita.
  sudo bash scripts/primebook-gnome-core.sh all
      Install packages, then apply the theme and create a Rofi launcher
      for the local user named "prime".
  bash scripts/primebook-gnome-core.sh launcher
      Create the Rofi application-launcher desktop entry.
EOF
}

install_packages() {
  [ "$(id -u)" -eq 0 ] || {
    echo "Run install as Debian root inside PRoot." >&2
    exit 1
  }
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y "${PACKAGES[@]}"
}

apply_theme() {
  [ -n "${HOME:-}" ] && [ "$HOME" != /root ] || {
    echo "Run theme as the normal desktop user (prime), not root." >&2
    exit 1
  }
  command -v xfconf-query >/dev/null 2>&1 || {
    echo "xfconf-query is unavailable; run this inside your XFCE session." >&2
    exit 1
  }

  local backup_dir="$HOME/.config/primebook/backups"
  mkdir -p "$backup_dir"
  chmod 700 "$HOME/.config/primebook" "$backup_dir"
  local backup="$backup_dir/xfce-appearance-before-gnome-core-$(date +%Y%m%d-%H%M%S).txt"
  xfconf-query -c xsettings -lv > "$backup" 2>/dev/null || true
  printf 'Saved previous XFCE XSettings to: %s\n' "$backup"

  xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s Adwaita 2>/dev/null ||
    xfconf-query -c xsettings -p /Net/ThemeName -s Adwaita
  xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s Adwaita 2>/dev/null ||
    xfconf-query -c xsettings -p /Net/IconThemeName -s Adwaita

  echo "Applied Adwaita GTK theme and icon theme to XFCE."
  echo "Some applications may need to be restarted to pick up the theme."
}

create_launcher() {
  [ -n "${HOME:-}" ] && [ "$HOME" != /root ] || {
    echo "Run launcher as the normal desktop user (prime), not root." >&2
    exit 1
  }
  mkdir -p "$HOME/.local/share/applications"
  cat > "$HOME/.local/share/applications/primebook-app-launcher.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=PrimeBook Application Launcher
Comment=Search and launch installed applications
Exec=rofi -show drun
Icon=system-search
Terminal=false
Categories=Utility;
EOF
  chmod 644 "$HOME/.local/share/applications/primebook-app-launcher.desktop"
  echo "Created PrimeBook Application Launcher desktop entry."
  echo "Bind 'rofi -show drun' in Settings > Keyboard > Application Shortcuts for a Super+Space launcher."
}

case "$ACTION" in
  install)
    install_packages
    ;;
  theme)
    apply_theme
    ;;
  launcher)
    create_launcher
    ;;
  all)
    install_packages
    if [ "$(id -u)" -eq 0 ]; then
      if id prime >/dev/null 2>&1; then
        runuser -u prime -- bash "$0" theme
        runuser -u prime -- bash "$0" launcher
      else
        echo "User 'prime' was not found; packages installed, but user appearance was not changed." >&2
      fi
    else
      apply_theme
      create_launcher
    fi
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
