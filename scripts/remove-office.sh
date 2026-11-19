#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

if ! command -v proot-distro >/dev/null 2>&1; then
  echo "proot-distro is missing. Install the project prerequisites first." >&2
  exit 1
fi

echo "== PrimeBook Office removal =="
echo "This removes only the optional LibreOffice Writer/Calc installation."
echo "The base desktop applications and your personal documents are not targeted."
echo

proot-distro login --isolated debian -- /bin/bash -s <<'DEBIAN_SCRIPT'
set -Eeuo pipefail
export DEBIAN_FRONTEND=readline

if ! command -v apt-get >/dev/null 2>&1; then
  echo "ERROR: Debian APT was not found." >&2
  exit 1
fi

office_packages=()
for package in libreoffice-writer libreoffice-calc; do
  if dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null | grep -qx installed; then
    office_packages+=("$package")
  fi
done

if [ "${#office_packages[@]}" -gt 0 ]; then
  echo "Removing installed Office applications: ${office_packages[*]}"
  apt-get purge -y "${office_packages[@]}"
else
  echo "LibreOffice Writer/Calc are not currently installed."
fi

PRIME_HOME="$(getent passwd prime | cut -d: -f6)"
if [ -z "$PRIME_HOME" ] || [ ! -d "$PRIME_HOME" ]; then
  PRIME_HOME="/home/prime"
fi

# These two desktop shortcuts are the only user-facing files created by
# install-apps.sh specifically for the --office option.
rm -f \
  "$PRIME_HOME/Desktop/libreoffice-writer.desktop" \
  "$PRIME_HOME/Desktop/libreoffice-calc.desktop"

echo
echo "== Previewing orphaned package cleanup =="
echo "APT may list unused dependencies from other installations too."
echo "Review the list carefully; nothing in this preview is removed."
apt-get autoremove --purge --dry-run

echo
read -r -p "Run the interactive autoremove cleanup shown above? [y/N] " answer
case "$answer" in
  y|Y|yes|YES)
    # Deliberately interactive: review APT's final list before confirming.
    apt-get autoremove --purge
    ;;
  *)
    echo "Skipped dependency cleanup. You can review it later with:"
    echo "  apt-get autoremove --purge"
    ;;
esac

echo
echo "Office removal finished."
echo "Personal files and LibreOffice user-profile data were left untouched."
echo "Other PrimeBook desktop applications and customizations were not targeted."
DEBIAN_SCRIPT
