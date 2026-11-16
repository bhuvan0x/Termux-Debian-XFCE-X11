# GNOME Software Center on Debian XFCE

This adds the GNOME Software storefront to the existing Debian 13 ARM64 XFCE desktop. It does **not** install GNOME Desktop or replace XFCE.

## Install

Run from Termux:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/install-gnome-software.sh
```

Or use the integrated refresh script to install the store, repair the WhiteSur startup race and restart the desktop once:

```bash
bash scripts/refresh-primebook.sh
```

## Included backends

- **Debian packages:** `gnome-software-plugin-deb` and PackageKit.
- **Flatpak apps:** `gnome-software-plugin-flatpak`, Flatpak and a per-user Flathub remote for `prime`.
- **App metadata:** AppStream and Debian's APT icon metadata configuration.
- **XFCE launcher:** Software Center in the Applications menu and on the desktop.

Debian 13 (Trixie) currently packages GNOME Software 48.3-2 for ARM64, with both Debian-package and Flatpak plugins available from the official Debian archive.

## PRoot limitations

GNOME Software is a graphical storefront, but PRoot is not a full systemd Linux boot. Its Debian-package install/update actions rely on PackageKit and system-bus/Polkit services, which may not be available in this environment. Flatpak application deployment may also be blocked by Android kernel sandbox/user-namespace restrictions. The installer does not disable sandboxing or weaken PRoot isolation to force these features.

If the catalogue opens but an install/update action fails, use the existing Debian package-management workflow:

```bash
bash scripts/update-debian.sh
```

Install individual packages through APT in the normal Debian root session. GNOME Software remains useful for discovering applications and viewing available metadata; backend compatibility must be tested on the device.
