# GNOME Core Experience for PrimeBook XFCE

PrimeBook keeps XFCE as the desktop session, window manager and panel framework. This integration adds selected GNOME/GTK applications and familiar GNOME-style workflows without installing GNOME Shell, GDM, Mutter or a second desktop session.

## Included

- Adwaita GTK theme and icon assets
- GNOME Calculator
- GNOME Text Editor
- Loupe image viewer
- Evince document viewer
- File Roller archive manager
- GNOME System Monitor
- GNOME Font Viewer
- dconf Editor
- Rofi application search/launcher
- XFCE notification daemon

The existing XFCE panel, Thunar, Plank dock, session startup and window manager remain in place.

## Install

From the Debian-side repository copy:

```bash
sudo bash scripts/primebook-suite.sh gnome-core install
```

Then, from the normal `prime` desktop terminal inside the running XFCE session:

```bash
bash scripts/primebook-suite.sh gnome-core theme
bash scripts/primebook-suite.sh gnome-core launcher
```

Or run the combined action as Debian root; it installs packages and applies the theme/launcher to the existing `prime` account:

```bash
sudo bash scripts/primebook-suite.sh gnome-core all
```

In PRoot, `sudo` is not a host privilege boundary; use the repository's established Debian root login method if sudo is unavailable.

## Launcher shortcut

The installer creates a desktop entry and recommends binding this command in XFCE Settings > Keyboard > Application Shortcuts:

```bash
rofi -show drun
```

Assign `Super+Space` if that key combination is not already used.

## Deliberately not installed

- GNOME Shell / Mutter / GDM
- GNOME session or systemd user services
- GNOME Online Accounts, GNOME Software or background services that assume a conventional systemd/logind host
- A second window manager or compositor

Full GNOME Shell integration is not the target for this PRoot setup. It would compete with the existing XFCE session and could depend on system services and compositor features not available in this environment.

## Reverting the appearance

The installer saves the prior XFCE XSettings values under:

```
~/.config/primebook/backups/
```

Restore the previous GTK theme and icon theme by reading the most recent `xfce-appearance-before-gnome-core-*.txt` backup and setting the corresponding values with `xfconf-query -c xsettings`. Removing the added applications is optional and does not affect XFCE's core session.
