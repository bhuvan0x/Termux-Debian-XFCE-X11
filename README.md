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
- XFCE desktop with a lightweight, dark appearance, custom wallpaper, larger desktop icons and a slim bottom panel.
- Firefox ESR, VLC, MPV, FFmpeg, Geany, file manager, PDF/image viewers, archive tools and system utilities.
- Clickable launchers on the Debian desktop.
- A dedicated unprivileged `prime` desktop account for GUI apps.
- Exactly two daily controls: Start All and Stop All. Start All launches X11, audio, CUPS and XFCE; Stop All shuts them down.
- Widget background tasks for Debian updates and desktop app refresh.
- CUPS printing with Epson ESC/P-R and Gutenprint driver packages for supported models.
- Android USB detection/permission diagnostics plus X11 input-device inspection.
- Optional LibreOffice and optional XFCE theme/panel plugins.

## Quick installation

Install Termux, Termux:X11, Termux:Widget and the separate Termux:API Android add-on from compatible sources/signing families. Termux:API's command-line package is installed by setup-termux.sh. Then in Termux:

```bash
pkg update && pkg upgrade -y
pkg install -y git
git clone https://github.com/bhuvan0x/Termux-Debian-X11.git
cd Termux-Debian-X11
chmod +x scripts/*.sh

bash scripts/setup-termux.sh
bash scripts/install-debian.sh
```

Open the Termux:X11 Android app, then launch the desktop:

```bash
bash scripts/start-all.sh
```

## Daily controls

After the initial setup, use only these two commands:

~~~bash
bash scripts/start-all.sh
bash scripts/stop-all.sh
~~~

Start All launches Termux:X11, PulseAudio, CUPS (when installed) and XFCE. Stop All shuts down XFCE, CUPS, the Termux:X11 server/viewer and PulseAudio.

## Termux:Widget controls

The setup creates scripts in `~/.shortcuts/` and `~/.shortcuts/tasks/`.

| Home-screen shortcut | Action |
|---|---|
| **Start All** | Starts X11, audio, CUPS and XFCE |
| **Stop All** | Stops the complete workstation stack |

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

## Epson printing and USB devices

The default Debian installation includes CUPS and Debian's ARM64 Epson ESC/P-R package, which matches the L3110's ESC/P-R print language. It also includes SANE's epson2 scanner backend; SANE lists the L3110 (USB ID 04b8:1142) as Complete. The L3110 is USB-only, with no built-in Wi-Fi/Ethernet. Direct USB use inside PRoot still depends on Android exposing the raw USB device; otherwise use a separate Linux USB print/scan server. See docs/USB-AND-PRINTING.md.

Run bash scripts/check-usb.sh (an occasional diagnostic command) to list Android-visible USB devices and inspect X11 input devices. Termux:API can request Android USB permission, but PRoot does not automatically expose raw USB devices to Debian/CUPS. Standard USB keyboard/mouse input is normally mediated by Android and delivered to the foreground X11 window. For the L3110's USB printer/scanner limitations, see [docs/USB-AND-PRINTING.md](docs/USB-AND-PRINTING.md).

## Repository layout

~~~text
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
    ├── install-termux-widget.sh
    ├── install-printing.sh
    ├── start-printing.sh
    ├── stop-printing.sh
    ├── check-usb.sh
    ├── start-all.sh
    ├── stop-all.sh
    ├── start-desktop.sh
    ├── stop-desktop.sh
    ├── update-debian.sh
    └── diagnose.sh
~~~
## Performance and compatibility

- The target is ARM64 Android hardware; Debian package availability depends on the configured Debian release and repositories.
- XFCE, MPV and lightweight utilities are better suited to mobile hardware than full desktop environments.
- Firefox and VLC can still be demanding; avoid running multiple heavy GUI apps at once.
- Android may kill background processes. Exempt Termux and Termux:X11 from battery optimization if the device offers that setting.
- This is not a VM and does not boot another kernel. systemd, kernel modules, nested containers and some hardware integrations may not work normally.
- Optional themes and plugins are installed only when available in the Debian repositories.

## Useful commands

```bash
bash scripts/start-all.sh
bash scripts/stop-all.sh
bash scripts/install-apps.sh
bash scripts/install-termux-widget.sh
bash scripts/update-debian.sh
bash scripts/diagnose.sh
bash scripts/check-usb.sh
```

## Disclaimer

Unofficial community setup. Debian, Termux, Termux:X11 and Termux:Widget are maintained by their respective projects. Review scripts before running them. No root access is required.

---

<p align="center">
  <b>Built for a portable Linux workflow.</b><br>
  <sub>Maintained by <a href="https://github.com/bhuvan0x">bhuvan0x</a></sub>
</p>
