# macOS-Inspired XFCE Top Bar

This profile adapts the top-panel approach used by [mac-kali](https://github.com/notyourbusinessss/mac-kali) to the PrimeBook's Debian 13 PRoot + XFCE 4.20 environment.

It deliberately does **not** copy mac-kali's destructive panel reset. It modifies only the active panel-1 geometry and the existing expandable separator. Existing panel plugin IDs, plugin configuration, the inactive original dock panel, and Plank are preserved.

## Apply

Run from Termux, not from the Debian terminal:

~~~bash
cd ~/Termux-Debian-X11
git pull --ff-only origin main
bash scripts/macos-topbar.sh apply
~~~

The script requires the Plank migration to be enabled first. It checks the live XFCE session D-Bus, confirms panel 1 is active, and requires an existing separator plugin before changing anything.

## Layout

- Panel 1: top-left anchored, full width, 30 px high, 16 px icons.
- Existing Applications menu remains on the left.
- The existing expandable separator pushes the current system tray, clock and session controls to the right.
- Panel stays visible.
- Plank remains the bottom dock and retains its own auto-hide configuration.

The XFCE position value p=6 means upper-left. Do not use p=1 for the top: p=1 is the right screen edge. References: [XFCE panel position discussion](https://forum.xfce.org/viewtopic.php?id=16859) and [XFCE panel position examples](https://github-wiki-see.page/m/hpaluch/hpaluch.github.io/wiki/XFCE).

## Status and rollback

~~~bash
bash scripts/macos-topbar.sh status
bash scripts/macos-topbar.sh rollback
~~~

The first application saves the panel XML and the original geometry values in ~/.config/primebook/. Rollback restores those saved values. It does not uninstall Plank or reactivate the old dock.

## Global application menu (optional next stage)

Debian 13 Trixie provides xfce4-appmenu-plugin for arm64. That plugin can display exported application menus in the XFCE panel, but applications also need a compatible GTK menu exporter. It is not installed or enabled by this profile; validate it separately before changing application launch environments. See [Debian's package details](https://packages.debian.org/trixie/xfce/xfce4-appmenu-plugin).
