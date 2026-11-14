# Termux Debian X11

> A practical Debian Linux desktop on Android — powered by **Termux**, **proot-distro**, and **Termux:X11**.

Turn an Android phone, tablet, or Chromebook into a portable Linux workstation with a Debian userspace and an XFCE desktop. This repository provides repeatable setup, launch, stop, update, and diagnostic scripts instead of a pile of copy-pasted commands.

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20ChromeOS-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android and ChromeOS">
  <img src="https://img.shields.io/badge/Linux-Debian-A81D33?style=for-the-badge&logo=debian&logoColor=white" alt="Debian">
  <img src="https://img.shields.io/badge/Desktop-XFCE-2284F2?style=for-the-badge&logo=xfce&logoColor=white" alt="XFCE">
  <img src="https://img.shields.io/badge/Display-Termux%3AX11-555555?style=for-the-badge" alt="Termux X11">
</p>

## What you get

- **Debian** — a real Debian userspace inside proot, without rooting Android.
- **XFCE** — a lightweight, familiar desktop environment.
- **Termux:X11** — native X server integration for Android.
- **Desktop applications** — Firefox ESR, VLC, MPV, Geany, PDF/image viewers, archive manager, calculator, and system tools.\n- **XFCE home-screen shortcuts** — clickable launchers in the Debian desktop for the installed applications.
- **Lifecycle scripts** — install, start, stop, update, and diagnose your environment.
- **Re-runnable setup** — scripts are designed to be safe to run again.

## Desktop preview

The target environment is a clean XFCE desktop, not a heavyweight virtual machine. It is intended for terminal work, coding, scripting, lightweight development, file management, and Linux learning.

## Requirements

- Android 7+ (newer Android versions are recommended).
- Termux from **F-Droid or the official Termux GitHub releases**. Do not mix Termux builds or add-ons from different signing sources.
- The separate **Termux:X11 Android app** and its Termux package.
- A working internet connection.
- At least 3–5 GB of free storage; more is recommended for development tools.
- A device with enough RAM for the desktop and the applications you intend to run.

Install the Android apps from their official sources:

- [Termux](https://github.com/termux/termux-app)
- [Termux:X11 app and instructions](https://github.com/termux/termux-x11)
- [Termux:X11 releases](https://github.com/termux/termux-x11/releases)
- [proot-distro documentation](https://github.com/termux/proot-distro)

**Important:** Install Termux and Termux:X11 from compatible sources. Android will reject add-ons signed with a different key.

## Quick start

Open Termux and run:

```bash
pkg update && pkg upgrade -y
pkg install -y git
git clone https://github.com/bhuvan0x/Termux-Debian-X11.git
cd Termux-Debian-X11
chmod +x scripts/*.sh
./scripts/setup-termux.sh
./scripts/install-debian.sh
```

After installation, open the **Termux:X11 Android app**, then return to Termux and run:

```bash
./scripts/start-desktop.sh
```

To stop the desktop:

```bash
./scripts/stop-desktop.sh
```

See [docs/INSTALLATION.md](docs/INSTALLATION.md) for the full walkthrough and [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) if anything goes wrong.

## Repository layout

```text
Termux-Debian-X11/
├── README.md
├── .gitignore
├── scripts/
│   ├── setup-termux.sh       # Termux packages and X11 repository
│   ├── install-debian.sh     # Debian + XFCE desktop installation
│   ├── start-desktop.sh      # Start X11 and XFCE
│   ├── stop-desktop.sh       # Stop the desktop session
│   ├── update-debian.sh      # Update Debian packages
│   └── diagnose.sh           # Collect environment diagnostics
└── docs/
    ├── INSTALLATION.md
    └── TROUBLESHOOTING.md
```

## Desktop applications\n\nThe default app bundle is installed automatically by `scripts/install-debian.sh`. For an existing Debian setup, run:\n\n```bash\nbash scripts/install-apps.sh\n```\n\nIncludes Firefox ESR, VLC, MPV, FFmpeg, Geany, Thunar, Mousepad, Ristretto, Atril, Xarchiver, Galculator, task manager, screenshot tool, and audio settings. Use `bash scripts/install-apps.sh --office` to add LibreOffice Writer and Calc (larger download). Apps appear as clickable shortcuts on the XFCE desktop. The graphical session runs as the unprivileged `prime` account.\n\n## Useful commands inside Debian

```bash
apt update
apt full-upgrade
apt install build-essential git python3 python3-pip
apt install neovim tmux
```

For a programming workstation, add only the languages, SDKs, and editors you actually need. Large IDEs and browser workloads can be demanding on mobile hardware.

## Design choices

| Component | Why it is used |
|---|---|
| Termux | Android-side package manager and shell |
| proot-distro | Runs Debian userspace without root |
| Debian | Stable general-purpose Linux base |
| XFCE | Lightweight desktop environment |
| Termux:X11 | Displays Linux GUI applications on Android |

This is **not a virtual machine** and does not boot a separate Linux kernel. PRoot provides a Linux-like userspace; Android still supplies the host kernel. Some low-level features, system services, hardware access, containers, and kernel-dependent software will not work as they do on a conventional Linux PC.

## Performance notes

- Keep Android battery optimization disabled for Termux if background sessions are being killed.
- Use a moderate screen resolution and avoid running too many GUI applications simultaneously.
- Prefer lightweight tools such as XFCE, Thunar, Mousepad, Neovim, and tmux.
- Keep sufficient free storage for Debian packages and caches.
- Do not run random root scripts or paste commands you do not understand.

## Updating

Update Termux packages:

```bash
pkg update && pkg upgrade -y
```

Update Debian:

```bash
./scripts/update-debian.sh
```

## Uninstalling

To remove the Debian rootfs, first stop the desktop, then run:

```bash
proot-distro remove debian
```

This permanently deletes the Debian filesystem and its files. Back up anything important first. Termux:X11 and Termux packages can be removed separately through Android/Termux.

## Disclaimer

This project is an unofficial community setup guide. Debian, Termux, proot-distro, and Termux:X11 are maintained by their respective projects. No root access is required. Installation changes packages and files inside your Termux environment; review scripts before running them.

---

<p align="center">
  <b>Built for a portable Linux workflow.</b><br>
  <sub>Maintained by <a href="https://github.com/bhuvan0x">bhuvan0x</a></sub>
</p>
