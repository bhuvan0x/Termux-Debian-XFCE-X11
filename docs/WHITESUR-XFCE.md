# WhiteSur XFCE desktop profile

This project keeps Debian XFCE running through Termux:X11 and adds an optional, reversible WhiteSur-inspired desktop profile. It does **not** replace XFCE with GNOME.

## Design

- WhiteSur Dark GTK styling for GTK applications.
- WhiteSur XFWM4 decorations where compatible with the installed XFCE version.
- WhiteSur icon theme; cursor theme is optional and must be checked separately.
- Existing XFCE panel retained and restyled as a slim top panel.
- Optional Plank dock at the bottom.
- Optional Conky desktop widgets for clock/date and lightweight system telemetry.
- Static wallpaper and matching terminal palette.

The intended result is a full desktop layout while preserving the existing Debian user, applications, panel plugins, launchers, Termux:X11 startup flow, audio setup, and security isolation.

## Important status

**This is a staged customization plan, not an unattended installer.** The first operation is a read-only audit. Do not install themes, packages, dock software, or widgets until the audit has been reviewed and the user explicitly approves the implementation.

The Primebook environment is ARM64 Android + Termux + isolated PRoot-Distro Debian + Termux:X11. Renderer behavior, memory headroom, X11 display dimensions, active D-Bus session, XFCE panel configuration, and compositor behavior must be inspected on the actual device before choosing settings.

## Phase 1: read-only audit

Run from the Debian `prime` account while XFCE is available:

```bash
bash scripts/audit-xfce-theme.sh
```

The script:
- reads OS, architecture, XFCE component versions, display/session variables, screen geometry, memory and storage;
- checks whether Plank, Conky, Picom, MPV and theme packages are already installed;
- reports current XFCE theme, icon, cursor, font, compositor and panel settings when `xfconf-query` is available;
- lists relevant configuration paths and metadata without printing their contents;
- does not install packages, download files, change settings, start/stop processes, or create backups.

Some details may be unavailable if the audit is run outside the active graphical session. Run it from a terminal inside the XFCE desktop for the most complete report.

## Phase 2: backup and change plan

After reviewing the audit, create a timestamped backup owned by `prime`. At minimum, preserve:
- `~/.config/xfce4/`
- `~/.config/gtk-3.0/` and `~/.config/gtk-4.0/` when present
- `~/.config/xfce4/xfconf/`
- `~/.config/autostart/`
- relevant user-local theme/icon directories
- current XFCE panel and session configuration exports
- a package inventory and a text record of current xfconf settings

Do not copy caches, browser profiles, credentials, tokens, or unrelated personal files into the backup. Do not overwrite an earlier backup. Record the backup path and verify the archive before making changes.

## Phase 3: install assets conservatively

Prefer user-local assets under `~/.themes`, `~/.icons`, and `~/.local/share`. Use upstream project releases/source and verify downloads before extraction. Do not run an opaque all-in-one installer with root privileges.

Potential upstream projects:
- WhiteSur GTK theme: https://github.com/vinceliuice/WhiteSur-gtk-theme
- WhiteSur icon theme: https://github.com/vinceliuice/WhiteSur-icon-theme
- Plank dock: https://launchpad.net/plank
- Conky: https://github.com/brndnmtthws/conky

The exact release, install options, dependencies, and compatibility must be checked at implementation time. Do not assume GNOME Shell themes/extensions are XFCE components. Do not install GNOME Shell, Dash to Panel, or GNOME-only extensions.

## Phase 4: configure the full XFCE layout

Proposed layout:
1. Keep the current XFCE panel and its launchers/plugins. Back it up before changing panel geometry or appearance.
2. Apply the GTK theme and matching XFWM4 theme through XFCE Settings / xfconf.
3. Apply the icon theme and, only if compatible, cursor theme.
4. Configure Plank as an optional user-session autostart item. Avoid duplicate launchers and test its window-detection behavior under Termux:X11.
5. Configure Conky with conservative update intervals and no expensive graphs or transparency effects by default.
6. Use a static wallpaper. Keep the existing wallpaper file and path untouched unless the user explicitly asks to change it.
7. Match XFCE Terminal colors and font without changing shell configuration.

## Phase 5: validation

After each change, check:
- XFCE panel and desktop icons remain visible and interactive.
- Window decorations and GTK controls render correctly.
- Plank stays below normal windows and does not cover the panel or desktop controls.
- Conky remains click-through where supported and does not obscure icons.
- No duplicate autostart instances appear after restarting the session.
- Termux:X11 remains responsive and memory use is acceptable.
- Existing launchers, applications, audio, printer and security workflows remain intact.

Do not enable extra compositing or GPU effects without checking the current renderer. Prefer XFCE's existing compositor configuration; do not add Picom unless a demonstrated compatibility need exists.

## Rollback

Rollback must restore the exact pre-change XFCE and GTK configuration from the recorded backup, remove only the new WhiteSur/Plank/Conky autostart entries created by this profile, and restore prior theme/icon/cursor selections. It must not remove unrelated themes, packages, applications, launchers, or user data.

If the desktop becomes unusable, stop the graphical session using the existing project Stop All control, restore the backed-up user configuration from a Debian shell, then start the desktop again. Never use `git reset --hard` or delete the whole `~/.config` directory as a rollback method.

## Scope boundaries

- No GNOME installation or desktop-environment replacement.
- No changes to Termux:X11 startup, PRoot isolation/bindings, PulseAudio, CUPS, or security hardening.
- No changes to system-wide GTK themes or shared application launchers unless separately reviewed.
- No Fresco or Lowpaper integration.
- No automatic package removal or cleanup.
