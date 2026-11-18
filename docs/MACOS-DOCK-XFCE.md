# macOS-inspired XFCE dock and app finder

This profile refines the existing Debian XFCE desktop for Termux:X11. It keeps XFCE and the current panel plugins/launchers.

## Apply

The recommended full setup is now integrated into `scripts/apply-whitesur.sh`; that installer also persists the dock and app-finder profile across XFCE logins. Use it for a complete setup:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/apply-whitesur.sh
```

Use the dock-only script below only when you want to retune the dock separately, without reinstalling the WhiteSur assets:

Run from Termux while the desktop is running:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/apply-macos-dock.sh
```

The script:
- Finds the live `xfce4-session` process and reads its actual D-Bus address from `/proc`; it does not trust stale `~/.dbus/session-bus` files or create a private session bus.
- Detects the existing auto-hidden panel, falling back to the last configured panel.
- Sets the dock to 52% width and bottom-center position, increases icon size, uses always-auto-hide for a reliable bottom-edge reveal, and hides task labels.
- Keeps the visible panel at 100% opacity and strengthens the dark-glass surface so the dock no longer looks washed out.
- Adds transparent expanding separators around the existing app-launcher/task group so the icons sit in the horizontal center without replacing or reordering existing launchers.
- Applies a liquid-glass-inspired GTK surface: translucent dark fill, rounded corners, a subtle light rim and soft hover treatment.
- Keeps all existing panel items and their order.
- Assigns Super+Space to compact app search and Super+E to the expanded application finder.

No desktop restart is required; only the panel is refreshed.

## Controls

| Shortcut | Action |
|---|---|
| Super + Space | Compact app search |
| Super + E | Expanded application finder with application grid and search |
| Pointer at bottom edge | Reveal the auto-hidden dock |

If a shortcut is already assigned by the desktop or keyboard layout, open **Settings → Keyboard → Application Shortcuts** and change the conflicting binding.

## Limitations

XFCE's built-in panel does not implement macOS Dock's animated icon magnification or true backdrop blur. The GTK styling gives a liquid-glass-inspired translucent surface and rounded rim; actual transparency depends on the active X11 compositor. This profile does not enable a new compositor or install Plank/Picom, to avoid destabilizing Termux:X11/PRoot.

## Scope

The script does not replace XFCE, install GNOME Shell or Plank, alter the top panel, delete/reorder launchers, restart Termux:X11, or change audio, CUPS, PRoot isolation or security settings.
