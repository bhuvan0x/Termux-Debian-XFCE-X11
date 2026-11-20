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

The script installs Debian's `plank` package, saves the current bottom panel ID and its exact auto-hide setting, configures that XFCE panel to auto-hide, creates a Plank XFCE autostart entry, and starts Plank in the current session. It does not delete panel plugins, launchers, panel IDs, or XFCE configuration.

Plank's preferences are available by **Ctrl + right-click** on the dock. Use Preferences to choose icon size, position, theme and hide behavior. The package's defaults are intentionally retained rather than forcing unverified dconf schema values.

## Check status

```bash
bash scripts/plank-dock.sh status
```

## Roll back

```bash
bash scripts/plank-dock.sh rollback
```

Rollback stops Plank, removes its autostart entry, restores the saved XFCE panel auto-hide value, and refreshes the panel. Plank remains installed so it can be tested again without another download; remove it separately with APT only if you no longer want it.

## Important compatibility note

XFCE does not provide a supported per-panel disable switch. This migration therefore preserves the original panel and uses XFCE's native always-auto-hide mode instead of deleting the panel. Both Plank and the XFCE panel may react to the bottom screen edge on some X11/compositor combinations. If they overlap, compete for focus, or flicker, roll back and keep the existing XFCE dock. Do not manually delete the saved state or panel configuration.

The existing WhiteSur login hook recognizes the Plank marker and will not reapply its old XFCE dock geometry while Plank mode is active. The standalone XFCE dock-tuning script also refuses to overwrite the active Plank setup.
