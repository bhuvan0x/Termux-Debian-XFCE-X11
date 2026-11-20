# Plank dock migration

Plank is an optional standalone application dock. It does not replace XFCE or its top panel. This migration gives Plank the bottom-dock role while retaining the existing XFCE panel configuration for rollback.

## Requirements

- Run from Termux, not from a Debian terminal.
- Start the PrimeBook desktop first with `start-all`.
- The migration requires the live XFCE session D-Bus and PRoot-Distro 5.8.0 or newer.

## Enable Plank

From the repository directory:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/plank-dock.sh install
```

The script installs Debian's `plank` package as root, saves the complete active XFCE panel-ID list and the bottom panel ID, removes only that panel ID from XFCE's active panel list, creates a Plank XFCE autostart entry, and starts Plank in the current session. The panel's plugin definitions, launchers, geometry and Xfconf properties remain stored and are restored by rollback.

Plank's preferences are available by **Ctrl + right-click** on the dock. Use Preferences to choose icon size, position, theme and hide behavior. The package's defaults are intentionally retained rather than forcing unverified dconf schema values.

## Check status

```bash
bash scripts/plank-dock.sh status
```

## Roll back

```bash
bash scripts/plank-dock.sh rollback
```

Rollback stops Plank, removes its autostart entry, restores the complete saved XFCE active panel-ID list, and refreshes the panel. Plank remains installed so it can be tested again without another download; remove it separately with APT only if you no longer want it.

## Important compatibility note

This migration deactivates the bottom dock by removing its ID from XFCE's active panel list. It does not delete the panel's saved Xfconf properties or plugin definitions. The script requires at least two panels and a bottom-centered panel it can identify safely; otherwise it stops without changing the layout. Do not manually delete the saved state or panel configuration.

The existing WhiteSur login hook recognizes the Plank marker and will not reapply its old XFCE dock geometry while Plank mode is active. The standalone XFCE dock-tuning script also refuses to overwrite the active Plank setup.
