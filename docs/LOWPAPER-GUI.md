# Lowpaper Control Center

A lightweight GTK3 desktop frontend for the existing lowpaper + MPV wallpaper engine. It does not replace or bundle lowpaper, change the X11 renderer, or run a second wallpaper daemon.

## Features

- Live lowpaper status polling.
- Add one or more video/image files, or add a folder for lowpaper's playlist/slideshow support.
- Start the selected files/folders with fill, fit or stretch scaling.
- Optional shuffle and audio playback.
- Pause, resume, next and stop controls.
- Enable/disable lowpaper login autostart.
- Reapply lowpaper's saved wallpaper configuration with `restore`.

The selected paths live in the GUI session; lowpaper itself stores the last applied wallpaper and startup configuration. The GTK app is a control surface, not a media preview/editor.

## Install

From the Termux checkout, with the Debian XFCE desktop already installed:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/install-lowpaper-gui.sh
```

The installer uses an isolated Debian PRoot session and binds only this repository read-only-by-convention at `/mnt/termux-debian-x11` for the installation step. It installs Python GTK3 dependencies and adds a launcher for the unprivileged `prime` desktop user.

Open **XFCE Applications → Settings → Lowpaper Control Center**. You can also launch it from an XFCE terminal:

```bash
lowpaper-control-center
```

## Notes

- The existing lowpaper executable and software-rendering configuration remain authoritative.
- The GUI requires an active XFCE/X11 session and a working lowpaper installation.
- For icon stacking problems, use **Reapply desktop layer**; this runs `lowpaper restore`. It cannot compensate for a failed XFCE compositor/RGBA integration, so inspect the desktop if icons remain obscured.
- No cloud service or paid API is used.
