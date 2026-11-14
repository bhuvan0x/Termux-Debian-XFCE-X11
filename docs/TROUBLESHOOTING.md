# Troubleshooting

## Termux:X11 shows a black screen

- Open the Termux:X11 Android app once before starting XFCE.
- Confirm the Termux package is installed: pkg list-installed | grep termux-x11.
- Confirm the display is :0: echo "$DISPLAY".
- Run bash scripts/diagnose.sh and inspect the launcher output.
- Force-stop and reopen the Termux:X11 app, then retry.

## termux-x11 command not found

Run bash scripts/setup-termux.sh. Confirm x11-repo is enabled and refresh packages with pkg update.

## Termux:Widget is empty

1. Install the Termux:Widget Android add-on from the same signing source as Termux.
2. Run bash scripts/install-termux-widget.sh.
3. Check that scripts exist in ~/.shortcuts/ and ~/.shortcuts/tasks/.
4. Remove and re-add the widget if it has cached an old list.

## USB device is not detected by Termux

- Confirm the device supports USB host/OTG mode and the cable/hub supports data, not charging only.
- For power-hungry devices, use a powered USB hub.
- Install/open the separate Termux:API Android add-on and run pkg install termux-api in Termux.
- Run bash scripts/check-usb.sh and inspect Android's USB permission dialog.
- If you reconnect the device, Android may enumerate it under a new device path; list it again.

## USB keyboard/mouse does not work in X11

- Confirm Android itself can type or move the pointer outside Termux.
- Open the Termux:X11 app and ensure it has focus.
- Start XFCE and run bash scripts/check-usb.sh; inspect the XInput list.
- Android may expose a physical keyboard/mouse through a virtual input device rather than a separate device label.

## USB printer/scanner does not appear in Debian

This is a PRoot/Android boundary, not necessarily a driver problem. termux-usb can request Android access and pass a file descriptor to a specially written Termux program, but does not expose every device as a normal /dev/bus/usb node for CUPS/SANE. Prefer network printing/scanning. Full detail: USB-AND-PRINTING.md.

## Epson L3110 printer or scanner is not detected

- The L3110 uses ESC/P-R for printing; Debian's printer-driver-escpr package is the matching driver family.
- SANE lists the L3110 scanner as supported by epson2 (USB ID 04b8:1142).
- Run bash scripts/check-usb.sh and inspect Android USB inventory, Debian /dev/bus/usb visibility, scanimage -L and XInput output.
- The L3110 is USB-only. It has no built-in Wi-Fi/Ethernet, so a wireless printer procedure for an L3150 does not apply.
- If Android can see the L3110 but PRoot cannot, this is USB passthrough, not the wrong driver. Use a separate Linux host as a CUPS/SANE server if direct USB passthrough cannot be made available.

## CUPS admin page does not load

- Run bash scripts/start-all.sh (CUPS starts with the workstation).
- Open http://127.0.0.1:631 inside the Debian browser.
- Inspect /var/log/cups/error_log inside Debian.
- Confirm CUPS is listening and the daemon survived in PRoot.

## CUPS asks for credentials or rejects administration

Set a password for the Debian desktop user, who is added to the lpadmin group:

~~~bash
proot-distro login debian -- passwd prime
~~~

Then authenticate to CUPS as prime.

## Firefox or VLC refuses to start as root

The graphical session must run as the unprivileged Debian account prime. Use bash scripts/start-all.sh; do not start XFCE as root.

## Desktop shortcuts do not appear

Run bash scripts/install-apps.sh and restart XFCE. Launchers are stored in /home/prime/Desktop.

## Dark theme or wallpaper did not apply

Run bash scripts/stop-all.sh and then bash scripts/start-all.sh. The first-login helper runs after the XFCE session initializes. If an optional theme package was unavailable, the helper falls back to Adwaita.

## Audio does not work

Audio forwarding depends on Termux PulseAudio and Android permissions. Run bash scripts/stop-all.sh, then bash scripts/start-all.sh to restart the complete audio and desktop stack.

## Android kills the desktop in the background

Remove battery restrictions for Termux and Termux:X11 where Android permits. Keep the device cool and connected to power for long sessions. Android vendors may still terminate background processes.

## Debian package errors

Inside Debian:

~~~bash
apt-get update
apt-get --fix-broken install
apt-get full-upgrade
~~~

If the rootfs is corrupted, back up important files before considering a reinstall. Removing the distro deletes its entire filesystem.

## Collect diagnostics

From the repository directory:

~~~bash
bash scripts/diagnose.sh
bash scripts/check-usb.sh
~~~

When asking for help, include full command output, Android version, device model, Termux source, and whether Termux:X11 opens successfully. Redact private paths or usernames.
