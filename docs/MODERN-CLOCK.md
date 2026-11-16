# PrimeBook Modern Clock integration

The standalone implementation lives in [bhuvan0x/Mordern_Gaming_Clock](https://github.com/bhuvan0x/Mordern_Gaming_Clock). This repository provides a small Termux-side bootstrap so both projects use the same installer and clock configuration rather than maintaining divergent copies.

The upstream KDE Modern Clock is a Plasma 6 applet and cannot run as an XFCE panel widget. The shared project recreates its clean digital-clock aesthetic with Conky, without installing KDE Plasma or changing the existing XFCE panels and dock.

## Install or update

Run from Termux:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/install-modernclock.sh
```

The bootstrap fetches the latest default-branch source from the standalone public repository and runs its installer. It installs Debian's `conky-all` and Noto Sans packages, configures the desktop clock for the unprivileged `prime` account, and creates an XFCE autostart entry.

## Remove

```bash
bash scripts/install-modernclock.sh --remove
```

The same shared installer removes only the clock process, its configuration and its autostart entry. Conky remains installed in case another desktop configuration uses it.

## Source of truth

- Standalone project and clock configuration: [Mordern_Gaming_Clock](https://github.com/bhuvan0x/Mordern_Gaming_Clock)
- Termux/Debian integration bootstrap: `scripts/install-modernclock.sh`

The clock uses an X11 ARGB desktop window. Transparency depends on Termux:X11 visual support. True background blur and animated icon effects are not provided; no compositor is added.
