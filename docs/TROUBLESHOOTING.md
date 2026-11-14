# Troubleshooting

## Termux:X11 shows a black screen

- Open the Termux:X11 Android app before starting XFCE.
- Confirm the Termux package is installed: `pkg list-installed | grep termux-x11`.
- Confirm the display is `:0`: `echo "$DISPLAY"`.
- Run `./scripts/diagnose.sh` and inspect errors from the launcher.
- Force-stop and reopen the Termux:X11 app, then retry the desktop launcher.

## `termux-x11` command not found

Run `./scripts/setup-termux.sh`. If the package cannot be found, verify that `x11-repo` is enabled and refresh package indexes with `pkg update`.

## Android kills the desktop in the background

Remove battery restrictions for Termux and Termux:X11 in Android settings where available. Keep the device cool and connected to power for long sessions. Android vendors may still terminate background processes.

## XFCE says another session is running

Close the existing desktop session cleanly using `./scripts/stop-desktop.sh`. Avoid deleting lock files or killing every process blindly. If it persists, inspect processes with `pgrep -af 'xfce|Xorg|termux.x11'`.

## Audio does not work

Audio forwarding depends on the Termux PulseAudio service and Android permissions. Start it in Termux with `pulseaudio --start`, then restart the Linux application. Audio support can vary by device and Android version.

## Debian package errors

Inside Debian, run:

```bash
apt-get update
apt-get --fix-broken install
apt-get full-upgrade
```

If the rootfs is corrupted, back up important files before considering a reinstall. Removing the distro deletes its entire filesystem.

## Collect diagnostics

From the repository directory:

```bash
./scripts/diagnose.sh
```

When asking for help, include the full command output, Android version, device model, Termux source, and whether the Termux:X11 app opens successfully. Redact usernames or paths if they contain private information.


## Firefox or VLC refuses to start as root

The project now starts XFCE as the unprivileged Debian account `prime`. Do not launch Firefox or VLC from a root desktop. If you upgraded an older setup, stop the old session and restart using `bash scripts/start-desktop.sh`.

## Desktop shortcuts do not appear

Run `bash scripts/install-apps.sh` from the repository directory, then log out of XFCE and restart the desktop. Shortcuts are installed under `/home/prime/Desktop`.
