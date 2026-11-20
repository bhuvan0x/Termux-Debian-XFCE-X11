# Troubleshooting

## XFCE launches but applications, terminal, panel or dock are missing

A previous package purge or `apt autoremove` can remove XFCE components while leaving user launchers and appearance settings behind. Do not reset the XFCE profile or reinstall Debian.

From Termux, pull the latest workstation branch and run the recovery script:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only origin feat/primebook-workstation-suite
bash scripts/repair-desktop.sh
```

The repair reinstalls the core XFCE session, panel, window manager, desktop, terminal, Thunar, Plank and the repository's desktop application bundle. It restores Plank autostart and preserves the existing `prime` user's Xfconf settings, WhiteSur theme, wallpaper and panel layout. It does not run `apt autoremove`.

Then restart the desktop:

```bash
stop-all
start-all
```

The startup script checks for essential XFCE executables and points to the repair command instead of launching an incomplete session.

## ClamAV reports that no database is available

Run the optional installer from Termux to install ClamAV and refresh its signatures:

```bash
bash scripts/install-clamav.sh
bash scripts/scan-files.sh
# Optional Android Downloads scan (one-session bind)
bash scripts/scan-files.sh --android-downloads
```

If signature updates fail, check network connectivity and retry `freshclam` from an isolated Debian root session. Do not treat a scan without current signatures as a clean result.

## PRoot-Distro is too old for isolated login

The workstation requires PRoot-Distro 5.8.0 or newer. In Termux, update it before running the desktop:

```bash
pkg update
pkg upgrade -y
pkg install proot-distro
bash scripts/security-check-termux.sh
```

Do not remove or reinstall the Debian rootfs to solve this version check. Update the Termux package first.

## Security hardening and audit

From Termux, run:

```bash
bash scripts/harden-debian.sh
bash scripts/security-audit.sh
```

The audit reports update status, sudo configuration, listening sockets, CUPS binding, SSH server presence and package-file checksum discrepancies. It does not certify the Android device as secure. PRoot cannot enforce host kernel firewall rules, AppArmor, kernel sysctls, systemd timers or auditd.


- Open the Termux:X11 Android app once before starting XFCE.
- Confirm the Termux package is installed: `pkg list-installed | grep termux-x11`.
- Confirm the display is `:0`: `echo "$DISPLAY"`.
- Run `bash scripts/diagnose.sh` and inspect the launcher output.
- Stop the workstation with `stop-all` or `bash scripts/stop-all.sh`. Stop All sends the Termux:X11 `ACTION_STOP` broadcast to close the Android viewer, then terminates the Termux-side X11 server.
- If the viewer remains open, force-stop the Termux:X11 Android app once, then retry. A black viewer after XFCE exits means the Android viewer is still open; it is separate from the XFCE session.

## termux-x11 command not found

Run `bash scripts/setup-termux.sh`. Confirm x11-repo is enabled and refresh packages with `pkg update`.

## Termux:Widget is empty

1. Install the Termux:Widget Android add-on from the same signing source as Termux.
2. Run `bash scripts/install-termux-widget.sh`.
3. Check that scripts exist in `~/.shortcuts/` and `~/.shortcuts/tasks/`.
4. Remove and re-add the widget if it has cached an old list.

## Termux terminal commands start-all / stop-all are not found

Run the setup or shortcut installer again from the repository directory:

```bash
bash scripts/setup-termux.sh
# or:
bash scripts/install-termux-widget.sh
```

The scripts create `$PREFIX/bin/start-all` and `$PREFIX/bin/stop-all`. If the current shell still cannot find them, run `hash -r` or open a new Termux session. Type the commands in lowercase with a hyphen; the Widget labels "Start All" and "Stop All" are not terminal commands.

## Git pull says local changes would be overwritten

Android/Termux filesystems can report executable-bit changes even when script contents are unchanged. The setup scripts configure repository-local `core.filemode=false` to ignore mode-only differences.

Check:

```bash
git config --get core.filemode
git diff --summary
```

The first command should print `false`. If the diff summary contains only mode changes (for example `100644 => 100755`), restore those mode-only changes once, then pull and set the config:

```bash
git restore scripts/*.sh
git pull --ff-only
git config core.filemode false
```

Do not use `git reset --hard` for this. If `git diff` shows content changes, inspect and preserve those changes instead of restoring them blindly. Do not run `chmod +x scripts/*.sh`; project commands invoke scripts with `bash`.

## USB device is not detected by Termux

- Confirm the device supports USB host/OTG mode and the cable/hub supports data, not charging only.
- For power-hungry devices, use a powered USB hub.
- Install/open the separate Termux:API Android add-on and run `pkg install termux-api` in Termux.
- Run `bash scripts/check-usb.sh` and inspect Android's USB permission dialog.
- If you reconnect the device, Android may enumerate it under a new device path; list it again.

## USB keyboard/mouse does not work in X11

- Confirm Android itself can type or move the pointer outside Termux.
- Open the Termux:X11 app and ensure it has focus.
- Start XFCE and run `bash scripts/check-usb.sh`; inspect the XInput list.
- Android may expose a physical keyboard/mouse through a virtual input device rather than a separate device label.

## USB printer/scanner does not appear in Debian

This is a PRoot/Android boundary, not necessarily a driver problem. termux-usb can request Android access and pass a file descriptor to a specially written Termux program, but does not expose every device as a normal `/dev/bus/usb` node for CUPS/SANE. Prefer network printing/scanning. Full detail: USB-AND-PRINTING.md.

## Epson L3110 printer or scanner is not detected

- The L3110 uses ESC/P-R. The L3110 Series PPD is included in ESC/P-R 1.8.8 and newer; Debian 13's original 1.7.17 build is too old.
- Re-run `bash scripts/install-printing.sh` to install/update CUPS, the printer driver and the **Epson L3110 Series Setup** shortcut on the desktop and in the Applications menu.
- Start the desktop with `start-all`, open **Epson L3110 Series Setup**, then use CUPS **Administration → Add Printer**.
- Run `bash scripts/check-epson-l3110.sh` to inspect the driver package, model entries, CUPS state, USB visibility and scanner detection.
- SANE lists the L3110 scanner as supported by epson2 (USB ID 04b8:1142).
- Run `bash scripts/check-usb.sh` for Android USB inventory and Debian `/dev/bus/usb` visibility.
- The L3110 is USB-only. It has no built-in Wi-Fi/Ethernet, so a wireless printer procedure for an L3150 does not apply.
- If Android can see the L3110 but PRoot cannot, this is USB passthrough, not the wrong driver. Use a separate Linux host as a CUPS/SANE server if direct USB passthrough cannot be made available.

## CUPS admin page does not load

- Run `start-all` (CUPS starts with the workstation).
- Open `http://127.0.0.1:631` inside the Debian browser.
- Inspect `/var/log/cups/error_log` inside Debian.
- Confirm CUPS is listening and the daemon survived in PRoot.

## CUPS asks for credentials or rejects administration

Set a password for the Debian desktop user, who is added to the lpadmin group:

```bash
proot-distro login --isolated debian -- passwd prime
```

Then authenticate to CUPS as `prime`.

## prime is not in the sudoers file

First check the actual Debian user identity and sudoers configuration from Termux:

```bash
proot-distro login --isolated debian -- bash -lc 'id prime; getent group sudo; grep -n "^%sudo" /etc/sudoers'
```

PRoot selected-user sessions may not expose the supplemental sudo group as expected. The repository's `install-apps.sh` now creates this explicit rule automatically. On an existing installation, rerun `bash scripts/install-apps.sh`; alternatively create the drop-in from Termux (which enters Debian as root):

```bash
proot-distro login --isolated debian -- bash -lc 'printf "%s\n" "prime ALL=(ALL:ALL) ALL" > /etc/sudoers.d/prime && chmod 0440 /etc/sudoers.d/prime && visudo -c'
```

Then fully stop and restart XFCE and test `sudo -v` in a new Debian terminal. The rule requires the `prime` password. Change it with `proot-distro login --isolated debian -- passwd prime`. Never put passwords in scripts or repository files.

## OpenCode Desktop is installed but does not open from the menu

Run `bash scripts/install-apps.sh` from Termux after pulling the latest repository. It creates a permanent OpenCode menu/desktop launcher that runs the ARM64 Electron app in the background with PRoot-compatible flags. Restart XFCE using `stop-all` and `start-all`.

OpenCode logs are saved to `~/Downloads/opencode-desktop.log` inside Debian. Inspect the latest output with:

```bash
tail -n 100 ~/Downloads/opencode-desktop.log
```

The `opencode` terminal command is not provided by the OpenCode Desktop `.deb`; install the separate OpenCode CLI if you need the terminal interface.

## Installing future local ARM64 .deb packages

Use `primebook-install-deb ~/Downloads/package.deb` from the Debian `prime` account. It checks that the package architecture is `arm64` or `all`, installs through GDebi, and refreshes detected Electron desktop launchers. It cannot make every package compatible with PRoot or supply missing libraries, drivers, kernel features or GPU support.

## GDebi opens but clicking Install does nothing

The normal GDebi GTK action can fail when its PolicyKit privilege hand-off is unavailable in a PRoot desktop. The repository app installer creates a per-user GDebi launcher that asks for the `prime` sudo password first, starts `gdebi-gtk` with administrator privileges, and keeps a terminal open to show errors.

From Termux, update the repository and reapply the desktop setup:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/install-apps.sh
```

Stop and restart XFCE with `stop-all` then `start-all`. Launch **GDebi Package Installer** from the desktop or open the `.deb` file in Thunar using GDebi. Do not close the terminal window while the install is running.

The diagnostic log is saved at:

```text
/home/prime/Documents/gdebi-install.log
```

To inspect it from a Debian terminal:

```bash
tail -n 100 ~/Documents/gdebi-install.log
```

The launcher also prints the selected package's architecture. On this ARM64 device, do not install a package marked `amd64`.

## XFCE taskbar icons are clipped, overlapped or hidden

The desktop setup now anchors panel 1 to the bottom screen edge (position `p=12`) and increases its height and icon size so the panel reserves its own screen area.

Reapply the layout by updating the repository and rerunning:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/install-apps.sh
```

Then run `stop-all` and `start-all` so the XFCE session reloads the panel settings.

## Visual Studio Code package architecture is wrong

This workstation targets ARM64. Check both Debian and the downloaded package:

```bash
dpkg --print-architecture
dpkg-deb -f code_*.deb Architecture
```

Both must say `arm64`. An `amd64` VS Code .deb is for Intel/AMD 64-bit Linux and its dependencies cannot be satisfied by an ARM64 Debian rootfs. Use the repository's official ARM64 installer:

```bash
bash scripts/install-vscode.sh
```

## VS Code installs but will not open from the XFCE menu

Under PRoot, Electron/Chromium sandboxing and GPU acceleration can prevent the desktop launcher from opening. Test from a Debian XFCE terminal:

```bash
code --no-sandbox --disable-gpu --verbose
```

If that works, create a per-user launcher override for `prime` under `~/.local/share/applications` by running the repository installer again:

```bash
exit
# Now in Termux:
bash scripts/install-vscode.sh
```

The installer writes only to prime's home directory and leaves package-owned launchers intact. The `--no-sandbox` option reduces Chromium renderer isolation and should only be used for this trusted local PRoot environment.

## VS Code asks for a keyring password

This is the desktop credential keyring, not a VS Code activation or license password. You can cancel the prompt and use the editor; secure credential storage and sign-in may not work until GNOME Keyring is configured. Do not enter your Android lock-screen password unless it is also the keyring password you intentionally created.

## Firefox or VLC refuses to start as root

The graphical session must run as the unprivileged Debian account `prime`. Use `start-all`; do not start XFCE as root.

## VLC opens only when launched from a terminal, or App Finder cannot find its plugins

On Debian ARM64 under PRoot/Termux:X11, VLC may start with only its core module when its default plugin search path is not resolved. The Qt interface and video playback work when VLC is launched with the Debian multiarch plugin directory explicitly set:

```bash
VLC_PLUGIN_PATH=/usr/lib/aarch64-linux-gnu/vlc/plugins \
  /usr/bin/vlc --ignore-config --no-video-title-show
```

The repository's `primebook-vlc` wrapper now exports this path by default while preserving an already-defined `VLC_PLUGIN_PATH`. The XFCE VLC launcher calls that wrapper, so App Finder and file-manager launches inherit the setting. The wrapper also keeps the existing X11/Qt/audio defaults and writes diagnostics to `~/Documents/vlc-launch.log`.

Apply the updated launcher from Termux:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/install-apps.sh
```

The installer now writes the managed wrapper-backed launcher to both the desktop and `~/.local/share/applications/vlc.desktop`, replacing a stale manual override automatically. Then refresh XFCE's application list (or log out and restart the desktop) and launch VLC from App Finder. Confirm the selected launcher with:

```grep '^Exec=' ~/.local/share/applications/vlc.desktop /usr/share/applications/vlc.desktop 2>/dev/null```

If VLC still fails, inspect the last launch log:

```bash
tail -n 80 ~/Documents/vlc-launch.log
```

## Desktop shortcuts do not appear

Run `bash scripts/install-apps.sh` and restart XFCE. Launchers are stored in `/home/prime/Desktop`.

## Dark theme or wallpaper did not apply

Run `stop-all` and then `start-all`. The first-login helper runs after the XFCE session initializes. If an optional theme package was unavailable, the helper falls back to Adwaita.

## Audio does not work

Start All starts PulseAudio in Termux and loads `module-native-protocol-tcp` on loopback if it is not already loaded. It then checks that Debian can connect to `tcp:127.0.0.1`.

From Termux, inspect the host server:

```bash
pactl info
pactl list short modules | grep module-native-protocol-tcp
```

Test Debian's connection:

```bash
proot-distro login --isolated debian -- bash -lc 'PULSE_SERVER=tcp:127.0.0.1 pactl info'
```

If the module is missing, load it once manually to test:

```bash
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
```

Then restart with `start-all`. Do not add duplicate TCP modules; the startup script checks whether one is already loaded. The bridge is restricted to localhost.

## Android kills the desktop in the background

Remove battery restrictions for Termux and Termux:X11 where Android permits. Keep the device cool and connected to power for long sessions. Android vendors may still terminate background processes.

## Debian package errors

Inside Debian:

```bash
apt-get update
apt-get --fix-broken install
apt-get full-upgrade
```

If the rootfs is corrupted, back up important files before considering a reinstall. Removing the distro deletes its entire filesystem.

## Collect diagnostics

From the repository directory:

```bash
bash scripts/diagnose.sh
bash scripts/check-usb.sh
```

When asking for help, include full command output, Android version, device model, Termux source, and whether Termux:X11 opens successfully. Redact private paths, tokens, passwords or usernames where possible.
