# PrimeBook Modern Clock

This adds a lightweight XFCE-compatible desktop clock inspired by Prayag2's KDE Modern Clock. The original is a Plasma 6 applet and cannot run as an XFCE panel widget, so this profile uses Conky as a transparent desktop layer instead of installing KDE Plasma.

## Install

Run from Termux:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/install-modernclock.sh
```

The installer adds Debian's `conky-all` and Noto Sans packages, writes a dedicated configuration at `/home/prime/.config/conky/primebook-modernclock.conf`, creates an XFCE autostart entry, and launches the clock in the current X11 session.

## Appearance and behavior

- Top-right desktop placement, with spacing below the existing top panel.
- Three-line layout: uppercase weekday, full date, and large 24-hour digital time.
- White text with a restrained WhiteSur blue accent.
- Transparent desktop window; no panel, dock, wallpaper, GTK theme, or XFCE settings are changed.
- Time refreshes every second; weekday text refreshes every minute.
- Runs as the unprivileged `prime` user.

Conky's transparent desktop window depends on the X11 server's ARGB visual support. If transparency is unavailable in a particular Termux:X11 build, the clock may render with a solid background; this does not affect the XFCE session.

## Remove

```bash
bash scripts/install-modernclock.sh --remove
```

This stops the clock and removes only this profile's configuration and autostart entry. It leaves the Conky package installed in case another configuration uses it. To remove Conky as well, run `apt-get remove conky-all` in a root Debian session.
