# macOS-inspired XFCE dock and app finder

This profile refines the existing Debian XFCE desktop for Termux:X11. It keeps XFCE and the current panel plugins/launchers.

## Apply

Run from Termux while the desktop is running:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/apply-macos-dock.sh
```

The script:
- Connects to the running XFCE session D-Bus (and refuses to continue if it cannot).
- Detects the existing auto-hidden panel, falling back to the last configured panel.
- Reduces its length, sets a larger icon size, enables auto-hide and hides task labels.
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

XFCE's built-in panel does not implement macOS Dock's animated icon magnification or its exact glass capsule appearance. The configuration uses native XFCE behavior to avoid a heavier replacement dock or compositor on Termux:X11/PRoot.

## Scope

The script does not replace XFCE, install GNOME Shell or Plank, alter the top panel, delete/reorder launchers, restart Termux:X11, or change audio, CUPS, PRoot isolation or security settings.
