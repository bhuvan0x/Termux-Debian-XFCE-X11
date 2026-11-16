# Prayag2 Modern Clock — centered transparent XFCE port

This integration installs the XFCE/Termux:X11 port of [Prayag2/kde_modernclock](https://github.com/Prayag2/kde_modernclock), maintained in [bhuvan0x/Mordern_Gaming_Clock](https://github.com/bhuvan0x/Mordern_Gaming_Clock).

The clock window is transparent and frameless, with the clock positioned at the horizontal and vertical center of the screen by default. It retains the upstream Anurati and Poppins fonts, typography, letter spacing, date/time layout, white text, and style characters.

## Install or update

Run from Termux:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/install-modernclock.sh
```

The bootstrap fetches the latest standalone installer, updates the QML and configuration files, and launches the clock. Re-running the installer replaces the running instance and refreshes its autostart configuration.

## Position

- Default: screen center.
- Drag the clock to move it manually.
- Edit `~/.local/share/modern-gaming-clock/config.js` as Debian user `prime` to set `center_offset_x` and `center_offset_y` for the next launch.

## Transparency note

The QML window has a transparent background and draws only the clock text. X11 transparency/compositing depends on Termux:X11 and the active XFCE window manager configuration. This setup does not install or enable a compositor.

## Remove

```bash
bash scripts/install-modernclock.sh --remove
```

This removes the clock and its autostart entry, including the previous Conky approximation's files. Shared Qt packages remain installed.
