#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Rebuild Fresco 1.1.55 with the X11 video output for Termux:X11/PRoot.
# Run from Termux after pulling this repository. The source tree is built as
# the unprivileged Debian user; only the final binary installation is root.

command -v proot-distro >/dev/null 2>&1 || {
  echo "proot-distro is missing. Run the Debian setup first." >&2
  exit 1
}

FRESCO_SOURCE="${1:-/home/prime/src/Fresco}"
proot-distro login --isolated debian -- /usr/bin/env \
  "FRESCO_SOURCE=$FRESCO_SOURCE" /bin/bash -s <<'DEBIAN_ROOT'
set -Eeuo pipefail

if [ "$(dpkg --print-architecture)" != "arm64" ]; then
  echo "This compatibility build currently targets Debian ARM64." >&2
  exit 2
fi

id prime >/dev/null 2>&1 || {
  echo "Debian user 'prime' does not exist." >&2
  exit 1
}

PRIME_HOME="$(getent passwd prime | cut -d: -f6)"
SOURCE_DIR="${FRESCO_SOURCE}"
PLAYER="$SOURCE_DIR/src/daemon/mpv/player.rs"

if [ ! -f "$SOURCE_DIR/Cargo.toml" ] || [ ! -f "$PLAYER" ]; then
  echo "Fresco source tree not found at: $SOURCE_DIR" >&2
  echo "Expected Cargo.toml and src/daemon/mpv/player.rs." >&2
  exit 1
fi

if ! grep -Eq '^version = "1\.1\.55"$' "$SOURCE_DIR/Cargo.toml"; then
  echo "Expected Fresco 1.1.55 source. Refusing to patch an unverified version." >&2
  grep -m1 '^version' "$SOURCE_DIR/Cargo.toml" || true
  exit 1
fi

if ! dpkg-query -W -f='${Status}' libmpv2 2>/dev/null | grep -q 'install ok installed'; then
  echo "libmpv2 is required. Install it before building Fresco." >&2
  exit 1
fi

echo "== Patching Fresco's embedded X11 MPV output =="
runuser -u prime -- env HOME="$PRIME_HOME" FRESCO_SOURCE="$SOURCE_DIR" \
  PATH="$PRIME_HOME/.cargo/bin:/usr/local/bin:/usr/bin:/bin" /bin/bash -s <<'BUILD_AS_PRIME'
set -Eeuo pipefail
cd "$FRESCO_SOURCE"
PLAYER="$FRESCO_SOURCE/src/daemon/mpv/player.rs"

if grep -q 'FRESCO_MPV_VO' "$PLAYER"; then
  echo "Compatibility override already present; leaving source unchanged."
else
  cp -n "$PLAYER" "$PLAYER.pre-termux-x11"
  python3 - "$PLAYER" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
anchor = (
    '        let hwdec = crate::config::hwdec(!wallpaper.rotation.is_multiple_of(360));\n'
    '        let opts: &[(&str, &str)] = &[\n'
)
replacement = (
    '        // Termux:X11 under PRoot has no usable EGL/GLX GPU context. Keep\n'
    '        // upstream GPU output as the default, but permit an explicit X11\n'
    '        // software-output override for embedded wallpaper windows.\n'
    '        let vo = std::env::var("FRESCO_MPV_VO")\n'
    '            .ok()\n'
    '            .filter(|value| matches!(value.as_str(), "gpu" | "x11"))\n'
    '            .unwrap_or_else(|| "gpu".to_string());\n'
    + anchor
)
if source.count(anchor) != 1:
    raise SystemExit("Expected unique MPV initialization anchor; source left unchanged.")
if source.count('            ("vo", "gpu"),\n') != 1:
    raise SystemExit("Expected unique embedded MPV GPU output option; source left unchanged.")
source = source.replace(anchor, replacement, 1)
source = source.replace('            ("vo", "gpu"),\n', '            ("vo", &vo),\n', 1)
path.write_text(source)
PY
fi

grep -n -A8 -B2 'FRESCO_MPV_VO' "$PLAYER"
echo
echo "== Building Fresco 1.1.55 (release, locked dependencies) =="
cargo build --release --locked
test -x target/release/fresco
test -x target/release/frescod
target/release/fresco --version
BUILD_AS_PRIME

echo
echo "== Verifying and installing rebuilt binaries =="
for binary in fresco frescod; do
  source="$SOURCE_DIR/target/release/$binary"
  missing="$(ldd "$source" 2>&1 | grep 'not found' || true)"
  if [ -n "$missing" ]; then
    echo "Unresolved libraries for $source:" >&2
    printf '%s\n' "$missing" >&2
    exit 1
  fi
  destination="/usr/local/bin/$binary"
  backup="$destination.before-termux-x11"
  if [ -x "$destination" ] && [ ! -e "$backup" ]; then
    cp -a "$destination" "$backup"
  fi
  install -o root -g root -m 0755 "$source" "$destination"
done

echo
echo "Fresco rebuilt and installed."
echo "The XFCE session must be restarted to inherit FRESCO_MPV_VO=x11."
echo "No wallpaper, user configuration, library entry, or daemon process was deleted."
DEBIAN_ROOT
