# Installation guide

## 1. Install the Android applications

Install Termux and the Termux:X11 Android application using the official project instructions. Keep their signing sources compatible. Do not install Termux from one source and its add-ons from an incompatible source.

- Termux: https://github.com/termux/termux-app
- Termux:X11: https://github.com/termux/termux-x11

Open Termux once and grant requested storage access only if you need shared-storage integration.

## 2. Clone this repository

```bash
pkg update && pkg upgrade -y
pkg install -y git
 git clone https://github.com/bhuvan0x/Termux-Debian-X11.git
cd Termux-Debian-X11
chmod +x scripts/*.sh
```

## 3. Prepare Termux

```bash
./scripts/setup-termux.sh
```

This installs the X11 package repository, proot-distro, PulseAudio, and the Termux:X11 package.

## 4. Install Debian and XFCE

```bash
./scripts/install-debian.sh
```

The first installation downloads a Debian root filesystem and desktop packages. It can take time and several gigabytes of storage.

## 5. Start the graphical session

1. Launch the **Termux:X11** Android app.
2. Return to Termux.
3. From the repository directory, run:

```bash
./scripts/start-desktop.sh
```

Keep the Termux session running while using the desktop. If the display is blank, check the troubleshooting guide.

## 6. Stop and update

```bash
./scripts/stop-desktop.sh
./scripts/update-debian.sh
```

## Optional developer tools

Inside Debian:

```bash
apt install -y neovim tmux clang cmake ninja-build gdb \
  nodejs npm default-jdk golang rustc cargo
```

Install only what you need. Package availability and versions depend on the Debian release configured by proot-distro.

## Notes and limitations

- This is Debian userspace under PRoot, not a full virtual machine and not a second kernel.
- Android remains the host operating system and controls hardware, power management, and kernel features.
- systemd services, kernel modules, Docker-style nested containers, and some low-level networking or hardware features are not expected to work normally.
- GUI performance and memory use depend heavily on the Android device.


## 7. Install the recommended desktop applications

Fresh installations do this automatically through `install-debian.sh`. To add or repair the application bundle later:

```bash
bash scripts/install-apps.sh
```

The bundle includes Firefox ESR, VLC, MPV, FFmpeg, Geany, Thunar, Mousepad, image and PDF viewers, archive manager, calculator, task manager, screenshot utility, and audio settings. It creates launchers in the Debian desktop user's `~/Desktop` folder.

Optional office suite (larger download and memory footprint):

```bash
bash scripts/install-apps.sh --office
```

The graphical session runs as the unprivileged Debian user `prime`, not root. This is important for VLC and browser security. Start it with `bash scripts/start-desktop.sh`.
