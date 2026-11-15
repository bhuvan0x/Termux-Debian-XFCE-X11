# Termux Debian X11

> A polished, lightweight Debian XFCE workstation for Android — powered by Termux, proot-distro and Termux:X11.

Build a practical Linux desktop on your Android tablet or Chromebook without rooting the device. This project automates the Debian userspace, XFCE desktop, everyday GUI applications, desktop shortcuts, PrimeBook styling and Termux:Widget controls.

<p align="center">
  <img src="https://img.shields.io/badge/Android-Termux-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android Termux">
  <img src="https://img.shields.io/badge/Linux-Debian-A81D33?style=for-the-badge&logo=debian&logoColor=white" alt="Debian">
  <img src="https://img.shields.io/badge/Desktop-XFCE-2284F2?style=for-the-badge&logo=xfce&logoColor=white" alt="XFCE">
  <img src="https://img.shields.io/badge/Architecture-ARM64-555555?style=for-the-badge" alt="ARM64">
</p>

## Highlights

- Debian userspace through `proot-distro`; no device root required.
- XFCE desktop with a lightweight, dark appearance, custom wallpaper, larger desktop icons and a properly bottom-anchored panel with room for taskbar icons.
- Firefox ESR, GDebi with a privileged diagnostic launcher, permanent OpenCode desktop launcher, and ARM64 `.deb` installation helper, VLC, MPV, FFmpeg, Geany, file manager, PDF/image viewers, archive tools and system utilities.
- Optional official Visual Studio Code ARM64 Debian package installer with a PRoot-compatible per-user XFCE launcher.
- A dedicated unprivileged `prime` desktop account for GUI apps.
- Exactly two daily controls: Start All and Stop All. Start All launches X11, audio, CUPS and XFCE; Stop All shuts them down, including the Android X11 viewer.
- Short Termux terminal commands: `start-all` and `stop-all`.
- Repository-local Git configuration ignores executable-bit-only changes on Android, avoiding recurring pull conflicts.
- Widget background tasks for Debian updates and desktop app refresh.
- Epson L3110 support: model-aware ARM64 ESC/P-R 1.8.8 driver with L3110 PPD, CUPS, scanner tools, and a dedicated **Epson L3110 Series Setup** desktop/menu shortcut.
- Android USB detection/permission diagnostics plus X11 input-device inspection.

## Quick installation

Install Termux, Termux:X11, Termux:Widget and the separate Termux:API Android add-on from compatible sources/signing families. Termux:API's command-line package is installed by setup-termux.sh.

This repository is private. Authenticate with GitHub CLI before cloning:

```bash
pkg update && pkg upgrade -y
pkg install -y git gh
gh auth login
gh auth setup-git
gh repo clone bhuvan0x/Termux-Debian-X11
cd Termux-Debian-X11

bash scripts/setup-termux.sh
bash scripts/install-debian.sh
```

Open the Termux:X11 Android app once, then launch the desktop:

```bash
start-all
```

## Daily controls

After initial setup, use either the short Termux commands:

```bash
start-all
stop-all
```

or the explicit script paths:

```bash
bash scripts/start-all.sh
bash scripts/stop-all.sh
```

Start All launches Termux:X11, PulseAudio, CUPS (when installed) and XFCE. It waits for the Termux PulseAudio server, loads the localhost-only TCP bridge once if missing, and checks that Debian can connect. Stop All shuts down XFCE, CUPS, the Termux:X11 Android viewer and server, and PulseAudio.

The Start All terminal remains occupied while XFCE runs. Use a second Termux session, the `stop-all` command, or the Stop All widget to shut it down.

## Git sync on Android

The setup script applies this repository-local setting:

```bash
git config core.filemode false
```

Android/Termux filesystems can report executable-bit changes differently from GitHub. This setting prevents mode-only changes from blocking `git pull`, while normal file-content changes remain visible. Do not run `chmod +x scripts/*.sh` after every pull; scripts are invoked with `bash`.

Update the project with:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
```

If an earlier local mode-only change is already blocking the first pull, inspect it with `git diff --summary`. If the output contains only `mode change 100644 => 100755` entries, use `git restore scripts/*.sh` once, pull, and then run `git config core.filemode false`. Do not use `git reset --hard` to solve this.

## Termux:Widget controls

The setup creates scripts in `~/.shortcuts/` and `~/.shortcuts/tasks/`.

| Home-screen shortcut | Action |
|---|---|
| **Start All** | Starts X11, audio, CUPS and XFCE |
| **Stop All** | Stops XFCE, CUPS, X11 viewer/server and audio |

Background tasks:

- **Update Debian packages** — apt update, full-upgrade and autoremove.
- **Refresh Debian desktop** — reruns the GUI app installer and desktop launchers.
- **Check USB devices** — runs the USB and XInput diagnostics.
- **Install printer support** — installs CUPS and the Epson/Gutenprint driver packages.

Install the Termux:Widget Android add-on from the same source/signing family as Termux, then add its widget from Android's home-screen widget picker. If you install Widget after the setup, run:

```bash
bash scripts/install-termux-widget.sh
```

Official project: https://github.com/termux/termux-widget

## Included applications

| App | Use |
|---|---|
| Firefox ESR | Web browser |
| GDebi | Local Debian package installer; terminal output is visible and saved to `~/Documents/gdebi-install.log` |
| OpenCode Desktop | Permanent XFCE launcher with PRoot-compatible Electron flags and log in `~/Downloads/opencode-desktop.log` |
| ARM64 local package helper | `primebook-install-deb /path/to/package.deb` validates `arm64`/`all` packages and refreshes detected Electron launchers |
| VLC / MPV | Video and audio |
| FFmpeg | Media conversion |
| Geany | Lightweight code editor |
| Thunar | File manager |
| Mousepad | Text editor |
| Ristretto | Image viewer |
| Atril | PDF viewer |
| Xarchiver | Archive manager |
| Galculator | Calculator |
| XFCE Task Manager | Process monitor |
| Screenshot tool | Desktop captures |
| PulseAudio Volume Control | Audio settings |

Optional office applications:

```bash
bash scripts/install-apps.sh --office
```

This installs LibreOffice Writer and Calc and uses more storage and RAM.

## Visual Studio Code (optional)

The project includes an ARM64-only installer for the official stable Debian package:

```bash
bash scripts/install-vscode.sh
```

Run it from Termux. It downloads the official `linux-deb-arm64` package, verifies the package architecture, installs it inside Debian, and creates a per-user XFCE launcher for `prime` using:

```text
--no-sandbox --disable-gpu
```

These options are a PRoot compatibility workaround. `--no-sandbox` weakens Chromium's normal renderer isolation; use this only in the trusted local PRoot desktop, not as a general Linux desktop recommendation. The launcher override is stored under `/home/prime/.local/share/applications` and does not modify the package-owned desktop files. The VS Code keyring prompt is separate from installation; credential storage may need GNOME Keyring configuration later.

Do not install an `amd64` VS Code package on this ARM64 Debian environment. GDebi is included for local `.deb` installation and dependency resolution, but it cannot convert an `amd64` package into an ARM64 package. Check a package before installing it with `dpkg-deb -f package.deb Architecture`.

## Debian sudo access

The desktop user `prime` is unprivileged. `scripts/install-apps.sh` creates a dedicated, password-authenticated sudoers drop-in for `prime`; this avoids relying only on supplemental group membership in a PRoot selected-user session. To reapply it on an existing installation, rerun `bash scripts/install-apps.sh`.

```bash
proot-distro login debian -- bash -lc 'printf "%s\n" "prime ALL=(ALL:ALL) ALL" > /etc/sudoers.d/prime && chmod 0440 /etc/sudoers.d/prime && visudo -c'
```

This requires running from Termux, which enters Debian as root. It grants `prime` password-authenticated sudo access. Never store a plaintext password in this repository.

## Epson printing and USB devices

The default Debian setup installs the ARM64 ESC/P-R 1.8.8 driver package, which contains the L3110 Series PPD, plus CUPS, Gutenprint and SANE scanner support. The installer temporarily pins only `printer-driver-escpr` from Debian Forky, then removes that source and pin. The L3110 is USB-only, with no built-in Wi-Fi/Ethernet. After `start-all`, open **Epson L3110 Series Setup** from the XFCE desktop or Applications menu to reach CUPS Administration and add the printer. The driver can be installed while the printer is unplugged; creating a working queue still requires CUPS to see the USB device. Android/PRoot does not automatically expose raw USB devices, so a separate Linux USB print/scan server may be needed. See docs/USB-AND-PRINTING.md.

Reapply printer support on an existing Debian installation with:

```bash
bash scripts/install-printing.sh
```

Check the driver, CUPS queue and scanner visibility with:

```bash
bash scripts/check-epson-l3110.sh
```

Run `bash scripts/check-usb.sh` (an occasional diagnostic command) to list Android-visible USB devices and inspect X11 input devices. Termux:API can request Android USB permission, but PRoot does not automatically expose raw USB devices to Debian/CUPS. Standard USB keyboard/mouse input is normally mediated by Android and delivered to the foreground X11 window. For the L3110's USB printer/scanner limitations, see [docs/USB-AND-PRINTING.md](docs/USB-AND-PRINTING.md).

## Repository layout

```text
Termux-Debian-X11/
├── README.md
├── docs/
│   ├── INSTALLATION.md
│   ├── TROUBLESHOOTING.md
│   └── USB-AND-PRINTING.md
└── scripts/
    ├── setup-termux.sh
    ├── install-debian.sh
    ├── install-apps.sh
    ├── install-vscode.sh
    ├── install-termux-widget.sh
    ├── install-printing.sh
    ├── check-epson-l3110.sh
    ├── start-printing.sh
    ├── stop-printing.sh
    ├── check-usb.sh
    ├── start-all.sh
    ├── stop-all.sh
    ├── start-desktop.sh
    ├── stop-desktop.sh
    ├── update-debian.sh
    └── diagnose.sh
```

## Performance and compatibility

- The target is ARM64 Android hardware; Debian package availability depends on the configured Debian release and repositories.
- XFCE, MPV and lightweight utilities are better suited to mobile hardware than full desktop environments.
- Firefox and VLC can still be demanding; avoid running multiple heavy GUI apps at once.
- Android may kill background processes. Exempt Termux and Termux:X11 from battery optimization if the device offers that setting.
- This is not a VM and does not boot another kernel. systemd, kernel modules, nested containers and some hardware integrations may not work normally.
- Optional themes and plugins are installed only when available in the Debian repositories.

## Useful commands

```bash
start-all
stop-all
bash scripts/install-vscode.sh
bash scripts/install-apps.sh
bash scripts/install-termux-widget.sh
bash scripts/update-debian.sh
bash scripts/diagnose.sh
bash scripts/check-usb.sh
bash scripts/check-epson-l3110.sh
```

## Disclaimer

Unofficial community setup. Debian, Termux, Termux:X11 and Termux:Widget are maintained by their respective projects. Review scripts before running them. No root access is required on Android; Debian root is provided by PRoot.

---

<p align="center">
  <b>Built for a portable Linux workflow.</b><br>
  <sub>Maintained by <a href="https://github.com/bhuvan0x">bhuvan0x</a></sub>
</p>
