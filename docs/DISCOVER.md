# KDE Discover on Debian XFCE

KDE Discover is the selected graphical software center for this Debian 13 ARM64 XFCE setup. It does not install KDE Plasma or replace XFCE.

## Install or update

Run from Termux:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/refresh-primebook.sh
```

The refresh installs Discover and its Flatpak backend, removes the previous GNOME Software frontend, applies the WhiteSur profile, and restarts the existing XFCE desktop. To install Discover without refreshing the desktop, run:

```bash
bash scripts/install-discover.sh
```

## Debian packages

The installer uses Debian 13 (Trixie) ARM64 packages from the configured Debian repositories:

- `plasma-discover` — graphical storefront and PackageKit integration.
- `plasma-discover-backend-flatpak` — Flatpak backend.
- `packagekit` — system package-management service.
- `flatpak` and `appstream` — Flatpak support and application metadata.
- `apt-config-icons` — Debian application metadata icons.

It does not add Debian testing/unstable repositories, install KDE Plasma, or replace XFCE. Flathub is configured as a per-user remote for `prime`.

## PRoot service handling

A normal PackageKit system service expects a system D-Bus. The existing desktop previously started only a per-user D-Bus session, which is why GNOME Software reported that it could not connect to the system bus.

The updated `start-desktop.sh` starts a temporary system D-Bus inside the same isolated root PRoot session that runs XFCE, verifies that the bus responds, and then drops privileges to the unprivileged `prime` account to start the desktop. The bus is tied to the desktop session and is terminated when that session exits. It does not start systemd, expose Termux home/storage, or change PRoot isolation.

If system D-Bus cannot start, XFCE is still allowed to launch; Discover records the failure in `/home/prime/Documents/discover.log`.

## Important limitations

Discover's Debian package backend uses PackageKit and may need PolicyKit authorization. PRoot does not provide a normal systemd/logind boot, so package installation through Discover may still be unavailable even when the system bus is reachable. The Flatpak backend may also be restricted by Android kernel sandbox/user-namespace support.

The graphical catalogue is useful for browsing application metadata. For dependable package operations, use the existing APT workflow from Termux/root Debian:

```bash
bash scripts/update-debian.sh
```

For a one-off package install, open a root Debian session and use `apt install package-name`. Do not add a broad PolicyKit allow-all rule or disable Flatpak sandboxing to force GUI installs.

## Diagnostics

Check system-bus connectivity from a Debian terminal:

```bash
dbus-send --system --print-reply --dest=org.freedesktop.DBus \\
  /org/freedesktop/DBus org.freedesktop.DBus.ListNames
```

Check Discover's launch log:

```bash
tail -n 100 ~/Documents/discover.log
```

If the system bus is unavailable, fully stop the desktop and restart it using `start-all`; do not launch a second system D-Bus from a separate PRoot session.
