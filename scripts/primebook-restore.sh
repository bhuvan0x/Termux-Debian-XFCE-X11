#!/usr/bin/env bash
set -Eeuo pipefail
ACTION="${1:-backup}"
BACKUP_DIR="${PRIMEBOOK_BACKUP_DIR:-$HOME/Backups/PrimeBook}"
mkdir -p "$BACKUP_DIR"; chmod 700 "$BACKUP_DIR"
case "$ACTION" in
 backup)
  stamp="$(date +%Y%m%d-%H%M%S)"; stage="$(mktemp -d)"; trap 'rm -rf "$stage"' EXIT
  mkdir -p "$stage/home-config" "$stage/manifests"
  for item in .config/xfce4 .config/primebook .config/autostart .config/Thunar .local/share/applications .local/share/xfce4; do
   if [ -e "$HOME/$item" ]; then mkdir -p "$stage/home-config/$(dirname "$item")"; cp -a "$HOME/$item" "$stage/home-config/$item"; fi
  done
  dpkg --get-selections > "$stage/manifests/dpkg-selections.txt" 2>/dev/null || true
  printf 'created=%s\nuser=%s\nscope=selected desktop configuration and package manifests only\n' "$(date)" "$(id -un)" > "$stage/RESTORE-INFO.txt"
  archive="$BACKUP_DIR/primebook-config-$stamp.tar.gz"; tar -C "$stage" -czf "$archive" .; chmod 600 "$archive"; sha256sum "$archive" > "$archive.sha256"
  echo "Created: $archive"; echo "Configuration-only restore point; not a full-system image."
  mapfile -t old < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'primebook-config-*.tar.gz' -printf '%T@ %p\n' | sort -nr | awk 'NR>5{$1="";sub(/^ /,"");print}')
  for f in "${old[@]}"; do rm -f -- "$f" "$f.sha256"; done
  ;;
 list) find "$BACKUP_DIR" -maxdepth 1 -type f -name 'primebook-config-*.tar.gz' -printf '%TY-%Tm-%Td %TH:%TM  %f\n' | sort -r || true ;;
 restore)
  archive="${2:-}"; [ -n "$archive" ] && [ -f "$archive" ] || { echo "Usage: $0 restore /path/to/archive.tar.gz" >&2; exit 2; }
  case "$(realpath "$archive")" in "$(realpath "$BACKUP_DIR")"/*) ;; *) echo "Archive must be inside $BACKUP_DIR" >&2; exit 3;; esac
  if [ -f "$archive.sha256" ]; then (cd "$(dirname "$archive")" && sha256sum -c "$(basename "$archive").sha256"); else echo "WARNING: no checksum file."; fi
  tar -tzf "$archive" >/dev/null
  read -r -p "This overwrites selected desktop settings in $HOME. Type RESTORE: " answer; [ "$answer" = RESTORE ] || exit 0
  stage="$(mktemp -d)"; trap 'rm -rf "$stage"' EXIT; tar -xzf "$archive" -C "$stage"
  for item in .config/xfce4 .config/primebook .config/autostart .config/Thunar .local/share/applications .local/share/xfce4; do
   if [ -e "$stage/home-config/$item" ]; then mkdir -p "$HOME/$(dirname "$item")"; cp -a "$stage/home-config/$item" "$HOME/$item"; fi
  done
  echo "Settings restored. Package manifests are reference-only; no packages were changed."
  ;;
 *) echo "Usage: $0 {backup|list|restore <archive.tar.gz>}" >&2; exit 2;;
esac
