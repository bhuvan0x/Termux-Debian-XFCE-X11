# Troubleshooting

## Termux:X11 shows a black screen

- Open the Termux:X11 Android app once before starting XFCE.
- Confirm the Termux package is installed: `pkg list-installed | grep termux-x11`.
- Confirm the display is `:0`: `echo "$DISPLAY"`.
- Run `bash scripts/diagnose.sh` and inspect the launcher output.
- Force-stop and reopen the Termux:X11 app, then retry.

## `termux-x11` command not found

Run `bash scripts/setup-termux.sh`. Confirm `x11-repo` is enabled and refresh packages with `pkg update`.

## Termux:Widget is empty or does not show shortcuts

1. Install the separate Termux:Widget Android add-on from the same source/signing family as Termux.
2. Run `bash scripts/install-termux-widget.sh` from the repository directory.
3. Confirm executable scripts exist in `~/.shortcuts/` and `~/.shortcuts/tasks/`.
4. Remove and re-add the Termux:Widget home-screen widget if it has cached an old list.

Official add-on: https://github.com/termux/termux-widget

## Widget shortcut cannot find the repository

The widget scripts store the repository's absolute path when generated. If you move or rename the clone, run `bash scripts/install-termux-widget.sh` again.

## Firefox or VLC refuses to start as root

The graphical session must run as the unprivileged Debian account `prime`. Use `bash scripts/start-desktop.sh`; do not start XFCE as root.

## Desktop shortcuts do not appear

Run `bash scripts/install-apps.sh` and restart XFCE. Launchers are stored in `/home/prime/Desktop`.

## Dark theme or wallpaper did not apply

Log out of XFCE, stop the session with `bash scripts/stop-desktop.sh`, and start it again. The first-login helper runs after the XFCE session initializes. If an optional theme package was unavailable, the helper falls back to Adwaita.

## Audio does not work

Audio forwarding depends on Termux PulseAudio and Android permissions. Start it in Termux with `pulseaudio --start`, then restart the desktop. Audio support varies by device and Android build.

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
```

When asking for help, include full command output, Android version, device model, Termux source, and whether Termux:X11 opens successfully. Redact private paths or usernames.
