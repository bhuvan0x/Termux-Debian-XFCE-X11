# Installation guide

## 1. Install the Android applications

Install these Android apps from compatible sources. Termux and its add-ons must use matching signing keys.

- Termux: https://github.com/termux/termux-app
- Termux:X11: https://github.com/termux/termux-x11
- Termux:Widget: https://github.com/termux/termux-widget

Install Termux:X11 and Termux:Widget from the same release family/source as Termux. Open each app once after installation.

## 2. Clone the repository

```bash
pkg update && pkg upgrade -y
pkg install -y git
git clone https://github.com/bhuvan0x/Termux-Debian-X11.git
cd Termux-Debian-X11
chmod +x scripts/*.sh
```

## 3. Prepare Termux and create widget shortcuts

```bash
bash scripts/setup-termux.sh
```

This updates Termux, installs the X11 repository, proot-distro, PulseAudio and Termux:X11 packages. It also creates Termux:Widget scripts in `~/.shortcuts` and `~/.shortcuts/tasks`.

If Termux:Widget is installed later, or you move the repository, regenerate its shortcuts:

```bash
bash scripts/install-termux-widget.sh
```

Then long-press the Android home screen, open **Widgets**, find **Termux:Widget**, and add it. The launcher shortcuts include Start Debian X11, Stop Debian X11, Restart Debian X11 and Debian Shell. Background tasks include Update Debian packages and Refresh Debian desktop.

## 4. Install Debian, XFCE and applications

```bash
bash scripts/install-debian.sh
```

This installs the Debian rootfs, XFCE and the default app bundle. The app installer creates a non-root desktop user named `prime`, application launchers in `/home/prime/Desktop`, a dark SVG wallpaper, and an XFCE autostart helper.

For an existing Debian installation, run:

```bash
bash scripts/install-apps.sh
```

Optional office suite (large download and memory footprint):

```bash
bash scripts/install-apps.sh --office
```

## 5. Start the desktop

Open the Termux:X11 Android app once. Then, from the repository directory:

```bash
bash scripts/start-desktop.sh
```

The launcher starts the X11 server, attempts to bring the Android X11 viewer to the foreground, starts localhost-only PulseAudio forwarding, and launches XFCE as the unprivileged `prime` account.

The XFCE first-login helper applies the available dark theme and icon theme, a custom PrimeBook wallpaper, larger desktop icons, and a slim bottom panel. Optional Debian theme and panel plugins are installed only if available in the configured repositories.

## 6. Stop and update

```bash
bash scripts/stop-desktop.sh
bash scripts/update-debian.sh
```

## 7. Optional developer tools

Inside Debian:

```bash
apt install -y neovim tmux clang cmake ninja-build gdb \
  nodejs npm default-jdk golang rustc cargo
```

Install only the toolchains you use; large language runtimes and IDEs can consume substantial storage and RAM.

## Notes and limitations

- This is Debian userspace under PRoot, not a virtual machine or a second kernel.
- Android remains the host OS and controls hardware, kernel features, power management and background process lifetime.
- systemd services, kernel modules, Docker-style nested containers and some low-level networking or hardware features are not expected to work like a conventional Linux PC.
- Firefox and VLC run under the non-root `prime` account. Do not start the graphical session as root.
- Performance depends on the PrimeBook's available RAM, thermal limits, Android build and Termux:X11 version.
