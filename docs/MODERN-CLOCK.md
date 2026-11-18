# Modern Gaming Clock — persistent XFCE Control Centre

This integration installs the clock maintained in [bhuvan0x/Mordern_Gaming_Clock](https://github.com/bhuvan0x/Mordern_Gaming_Clock), a transparent Qt Quick/XFCE port of [Prayag2/kde_modernclock](https://github.com/Prayag2/kde_modernclock).

## Install or update

Run from Termux:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/install-modernclock.sh
```

The bootstrap fetches the standalone clock repository and runs its installer inside Debian. The installer installs the Qt Quick Controls and persistent Qt Settings modules, wallpaper sampling support and the original fonts. It updates the deployed QML app and refreshes the XFCE autostart entry.

## Control Centre

Right-click the clock to open its Control Centre.

- **Region and time:** choose an IANA time zone (including custom entries), regional locale, 12/24-hour time and date format.
- **Display:** toggle weekday, date and time independently; adjust each text size.
- **Wallpaper-aware appearance:** sample the current XFCE wallpaper and choose contrasting light/dark text, or force white/dark text.
- **Position:** drag the clock with the left mouse button; use the Control Centre to recenter it.

The clock formats the current instant in the selected time zone. It does not change Android's or Debian's system clock. The time-zone choice affects the clock display only.

## Persistence across Stop All / Start All

The app stores preferences and window coordinates in Qt's per-user settings store under `/home/prime/.config`. The installed application and XFCE autostart entry live under:

- `/home/prime/.local/share/modern-gaming-clock/`
- `/home/prime/.config/autostart/modern-gaming-clock.desktop`

These are inside Debian's persistent PRoot root filesystem, not `/tmp` or the disposable XFCE session cache. `stop-all` stops the desktop processes; `start-all` starts XFCE and its autostart applications again. The clock therefore restores its saved region, display options, theme mode and last position.

## Wallpaper sampling

At startup, the clock reads the selected XFCE wallpaper path, samples a small thumbnail with Pillow, and chooses a contrasting text colour. When a wallpaper is changed, restart the clock or desktop to refresh the sampled contrast.

## Transparency

The QML window is frameless and transparent. Actual X11 compositing depends on Termux:X11 and the active XFCE window manager configuration; this integration does not install or enable a compositor.

## Remove

```bash
bash scripts/install-modernclock.sh --remove
```

This removes the clock application and its autostart entry. Shared Qt packages and saved Qt settings are retained.
