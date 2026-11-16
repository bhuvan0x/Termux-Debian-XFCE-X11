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
- PrimeBook WhiteSur XFCE desktop profile: WhiteSur Dark/Blue styling, matching dark icons and cursors, wallpaper, Noto Sans typography, and a persistent floating auto-hidden dock with app-finder shortcuts. Existing panel items and Linux services are preserved.
- KDE Discover software center with Flatpak backend and session-scoped system-D-Bus startup (PackageKit/Flatpak PRoot limitations documented), Firefox ESR, GDebi with a privileged diagnostic launcher, permanent OpenCode desktop launcher, and ARM64 `.deb` installation helper, VLC, MPV, FFmpeg, Geany, file manager, PDF/image viewers, archive tools and system utilities.
- Optional official Visual Studio Code ARM64 Debian package installer with a PRoot-compatible per-user XFCE launcher.
- A dedicated unprivileged `prime` desktop account for GUI apps.
- Optional ARM64 ClamAV scanner for on-demand file checks inside Debian (no always-on scanner daemon).
- Isolated PRoot sessions (PRoot-Distro 5.8.0+): Termux home, shared storage and app paths are not exposed to Debian by default; only the X11 socket is explicitly shared with XFCE.
- Security hardening and audit scripts: signed-APT enforcement, short sudo credential caching, CUPS loopback binding, package-file integrity checks, and Termux/PRoot version checks.
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
bash scripts/harden-debian.sh
bash scripts/security-audit.sh
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
- **Harden Debian** — applies conservative security defaults and restricts CUPS to loopback.
- **Security audit** — reviews host package versions, Debian packages, sudoers, listeners, CUPS and package-file checksums.
- **Termux security check** — checks the Termux app environment and PRoot-Distro version.
- **Install ClamAV** — installs the optional ARM64 antivirus CLI and updates signatures.
- **Update ClamAV signatures** — manually refreshes its malware definitions.
- **Scan Debian Downloads** — scans `/home/prime/Downloads` without deleting or quarantining files.

Install the Termux:Widget Android add-on from the same source/signing family as Termux, then add its widget from Android's home-screen widget picker. If you install Widget after the setup, run:

```bash
bash scripts/install-termux-widget.sh
```

Official project: https://github.com/termux/termux-widget

## Included applications

| App | Use |
|---|---|
| KDE Discover | Modern software storefront with PackageKit and Flatpak backends; install/update support depends on PRoot services |
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

## KDE Discover Software Center

Install KDE Discover without installing KDE Plasma or replacing XFCE:

```bash
bash scripts/install-discover.sh
```

The installer uses Debian 13 ARM64 packages, adds Discover's Flatpak backend and a per-user Flathub remote, and replaces the previous GNOME Software launcher. It does not add testing/unstable repositories or relax Flatpak sandboxing.

The desktop startup now launches a temporary system D-Bus inside the same isolated root PRoot session as XFCE, verifies the bus, and runs the graphical desktop as the unprivileged `prime` user. The bus exits with the desktop; no systemd service or broad Android storage bind is added.

**PRoot limitation:** Discover's APT backend uses PackageKit and may require PolicyKit authorization. Flatpak deployment may be restricted by Android kernel sandbox/user-namespace support. The storefront may work for browsing even if GUI installation is unavailable. For dependable package installation and updates, use APT through the existing root Debian workflow. See [docs/DISCOVER.md](docs/DISCOVER.md).

For a combined Discover install + WhiteSur startup repair + desktop restart:

```bash
bash scripts/refresh-primebook.sh
```

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

## Security hardening and maintenance

Run these from **Termux**, in this order, after pulling the latest repository:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
pkg update && pkg upgrade -y
pkg install -y proot-distro iproute2
bash scripts/security-check-termux.sh
bash scripts/harden-debian.sh
bash scripts/security-audit.sh
```

The isolated-session workflow requires PRoot-Distro **5.8.0 or newer**. The scripts stop rather than silently falling back to a less isolated session. Keep Termux, Termux:X11 and their add-ons updated from compatible signing sources.

Hardening applies signed-APT settings, installs `debsums` for package-file integrity checks, tightens password-authenticated sudo defaults, and configures CUPS to listen on loopback only with printer sharing disabled. The default audit is a quick review; run `bash scripts/security-audit.sh --integrity` to perform the slower full package-file checksum scan. Debian maintenance remains deliberate: run `bash scripts/update-debian.sh` regularly, then review `bash scripts/security-audit.sh`. PRoot does not provide a working systemd timer here, so the project does not claim unattended security updates.

PRoot-Distro's `--isolated` option removes automatic bindings for the Termux home directory, Android shared storage and Termux app paths. The XFCE session uses `--shared-x11` to expose only the X11 socket it needs. This means Android Downloads and Termux files are no longer automatically visible inside Debian. When a transfer is needed, explicitly bind only the required directory for that session; do not re-enable broad shared-home or shared-tmp mounts.

For example, to expose only Android's Downloads folder for one temporary Debian session, run this in Termux:

```bash
termux-setup-storage
proot-distro login --isolated --bind "$HOME/storage/shared/Download:/mnt/android-downloads" debian
```

The directory appears inside that session at `/mnt/android-downloads`; it is not mounted into normal desktop sessions.

**What this cannot secure from inside Debian:** PRoot shares the Android kernel and app UID. It is not a VM or a kernel-enforced container. Debian cannot independently enforce a host firewall, AppArmor/SELinux policy, kernel sysctls, kernel audit, systemd service timers, or kernel namespaces. Do not install UFW/Fail2ban and assume they protect the Android device. The Android OS remains the security boundary.

On Android, use a strong screen-lock PIN/password, install Termux and add-ons only from trusted compatible sources, keep Android security updates and Play Protect enabled, review app permissions, and avoid granting broad file access unless required. Keep backups of important Termux and Debian data. Never put passwords, API keys, SSH private keys or GitHub tokens in this repository.

Some Electron apps (including the OpenCode/VS Code compatibility launchers) require `--no-sandbox` under PRoot. This weakens Chromium isolation. Install only trusted builds, verify vendor checksums/signatures where provided, and do not use those launchers for untrusted applications or browsing. A clean audit is useful evidence, not a guarantee that the device is secure.

### Optional on-demand malware scanning

Install ClamAV from the Debian ARM64 repository:

```bash
bash scripts/install-clamav.sh
bash scripts/update-clamav.sh
bash scripts/scan-files.sh
# Or scan Android Downloads through a one-session bind:
bash scripts/scan-files.sh --android-downloads
```

By default, this scans `/home/prime/Downloads` inside Debian and writes a report to `/home/prime/Documents/clamav-scan.log`. You can pass another absolute Debian path, or use `bash scripts/scan-files.sh --android-downloads` to bind only Android's Downloads folder for that scan. The scanner never deletes files automatically. ClamAV is an additional file scanner, not a substitute for Android Play Protect or safe package verification; it cannot scan Android shared storage while the Debian session is isolated, and large files/archives may be skipped by scanner limits.

## Debian sudo access

The desktop user `prime` is unprivileged. `scripts/install-apps.sh` creates a dedicated, password-authenticated sudoers drop-in for `prime`; this avoids relying only on supplemental group membership in a PRoot selected-user session. To reapply it on an existing installation, rerun `bash scripts/install-apps.sh`.

```bash
proot-distro login --isolated debian -- bash -lc 'printf "%s\n" "prime ALL=(ALL:ALL) ALL" > /etc/sudoers.d/prime && chmod 0440 /etc/sudoers.d/prime && visudo -c'
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
├── assets/
│   └── primebook-midnight.svg
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
    ├── diagnose.sh
    ├── harden-debian.sh
    ├── security-audit.sh
    ├── security-check-termux.sh
    ├── install-clamav.sh
    ├── update-clamav.sh
    └── scan-files.sh
```

## Performance and compatibility

- The target is ARM64 Android hardware; Debian package availability depends on the configured Debian release and repositories.
- XFCE, MPV and lightweight utilities are better suited to mobile hardware than full desktop environments.
- Firefox and VLC can still be demanding; avoid running multiple heavy GUI apps at once.
- Android may kill background processes. Exempt Termux and Termux:X11 from battery optimization if the device offers that setting.
- This is not a VM and does not boot another kernel. systemd, kernel modules, nested containers and some hardware integrations may not work normally.
- Optional themes and plugins are installed only when available in the Debian repositories.

## XFCE Modern Gaming Clock

The shared clock implementation is maintained in [bhuvan0x/Mordern_Gaming_Clock](https://github.com/bhuvan0x/Mordern_Gaming_Clock). This repository contains a small bootstrap that fetches and runs that project's installer, keeping both repositories in sync.

Install or refresh it from Termux:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/install-modernclock.sh
```

Remove the clock profile with:

```bash
bash scripts/install-modernclock.sh --remove
```

The clock is an XFCE-native Conky desktop layer; it does not install KDE Plasma or alter the existing dock and panels. See [docs/MODERN-CLOCK.md](docs/MODERN-CLOCK.md).

## WhiteSur XFCE desktop customization

Apply the installed WhiteSur profile with one command from Termux:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/apply-whitesur.sh
```

The script runs inside the isolated Debian `prime` account, verifies or repairs the WhiteSur GTK/XFWM theme, dark icon pack and cursor pack, installs the wallpaper, and applies the complete persistent desktop profile.

Profile:
- WhiteSur Dark GTK theme with blue accent and matching XFWM4 window decorations.
- WhiteSur dark application icons and matching cursor theme.
- WhiteSur wallpaper and Noto Sans desktop typography.
- Floating, auto-hidden bottom-center dock with centered app icons, larger icon sizing, and a liquid-glass-inspired translucent GTK surface; existing panel items and launchers are preserved.
- **Super + Space** opens compact app search; **Super + E** opens the expanded application finder.
- XFCE autostart restores the appearance and dock profile on every login; GTK fallback settings are also saved.

One command applies the whole profile:

```bash
bash scripts/apply-whitesur.sh
```

Run it from Termux after `git pull --ff-only`. The installer restarts the existing desktop once during setup. No GNOME desktop, GNOME Shell extensions, Plank, Conky or Picom is installed. Audio, printer, PRoot isolation and security configuration are left untouched.

For details, troubleshooting and rollback, see [docs/WHITESUR-XFCE.md](docs/WHITESUR-XFCE.md).
 
## Useful commands

```bash
start-all
stop-all
bash scripts/install-vscode.sh
bash scripts/install-apps.sh
bash scripts/install-termux-widget.sh
bash scripts/update-debian.sh
bash scripts/diagnose.sh
bash scripts/security-check-termux.sh
bash scripts/install-clamav.sh
bash scripts/update-clamav.sh
bash scripts/scan-files.sh
bash scripts/scan-files.sh --android-downloads
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



## macOS-inspired floating dock and app finder

After pulling the latest changes, run this **from Termux while the XFCE desktop is running**:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/apply-macos-dock.sh
```

This updates the live XFCE session without restarting Debian, Termux:X11, audio or CUPS. It reuses the existing bottom panel and its current launchers/items, changes it to a shorter auto-hidden dock, and makes the existing task list icon-only. Move the pointer to the bottom screen edge to reveal it.

Keyboard shortcuts:
- **Super + Space** — compact app search (Spotlight-style).
- **Super + E** — expanded application finder (Launchpad-style grid with search).

The script detects the live XFCE D-Bus session and stops with an error if it cannot reach it; it does not write settings to a private temporary D-Bus session. It does not delete or reorder panel items.

**XFCE limitation:** the built-in panel does not provide macOS-style animated icon magnification or a true glass floating capsule. This profile uses native XFCE panel capabilities for a lightweight, stable dock. It does not install Plank, GNOME Shell or a compositor.
