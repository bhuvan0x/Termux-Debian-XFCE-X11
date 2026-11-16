# Prayag2 Modern Clock — XFCE port

This integration installs a faithful desktop port of [Prayag2/kde_modernclock](https://github.com/Prayag2/kde_modernclock) for the existing Debian 13 XFCE + Termux:X11 environment.

The original project is a Plasma 6 applet, so its Plasma shell cannot be loaded directly by XFCE. The standalone project replaces only that Plasma-specific shell with a transparent, frameless Qt Quick window. It retains the upstream three-row design, Anurati/Poppins font files, font sizes, letter spacing, default colours, date format, 12-hour time format and style-character output.

## Exact upstream defaults

- Day: Anurati, 72 px, 17 px letter spacing, uppercase.
- Date: Poppins, 19 px, 3 px letter spacing, `dd MMM yyyy`, uppercase.
- Time: Poppins, 19 px, 3 px letter spacing, 12-hour format with AM/PM.
- Style character: hyphen before and after time.
- All text: white; column spacing: 5 px.

The font files are fetched from the upstream repository at installation time; they are not replaced with system substitutes.

## Install or update

Run from Termux:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/install-modernclock.sh
```

The bootstrap fetches the latest standalone installer from [bhuvan0x/Mordern_Gaming_Clock](https://github.com/bhuvan0x/Mordern_Gaming_Clock). That installer installs the Qt 6 QML runtime, retrieves the original Anurati and Poppins font assets, installs the clock under `/home/prime/.local/share/modern-gaming-clock`, creates an XFCE autostart entry and launches it.

## Customize

As Debian user `prime`, edit:

```text
~/.local/share/modern-gaming-clock/config.js
```

This exposes the original visibility, font size, letter spacing, colour, date-format, 12/24-hour and style-character settings. Drag the clock to reposition it; change `window_margin_right` and `window_margin_top` for its next launch position.

## Remove

```bash
bash scripts/install-modernclock.sh --remove
```

This removes the clock and autostart entry, and cleans up the previous Conky approximation. Shared Qt packages remain installed.

## Fidelity boundary

The displayed typography, layout and output defaults follow the upstream applet. The KDE Plasma applet frame/shadow and Plasma settings dialog are not part of the XFCE port; a normal frameless desktop window and editable config file replace them. Transparency and desktop stacking depend on Termux:X11/XFWM. No KDE Plasma session or compositor is installed.
