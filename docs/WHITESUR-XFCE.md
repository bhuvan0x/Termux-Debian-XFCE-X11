# WhiteSur XFCE desktop profile

This project applies a WhiteSur Dark / Blue appearance to the existing Debian XFCE desktop running through Termux:X11. It does **not** replace XFCE with GNOME.

## Apply the profile

Run from Termux, not from inside Debian:

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
bash scripts/apply-whitesur.sh
```

The script:
1. Enters Debian using the isolated PRoot session as the unprivileged `prime` user.
2. Detects the installed WhiteSur GTK/XFWM theme directory rather than assuming a hard-coded directory name.
3. Verifies the WhiteSur dark icon and cursor assets, rebuilding/installing them only if missing.
4. Copies the upstream WhiteSur static wallpaper into `~/.local/share/backgrounds`.
5. Writes GTK, XFWM4, icon, cursor and XFCE wallpaper selections to the `prime` user's persistent XFConf configuration.
6. Installs `~/.config/autostart/primebook-whitesur.desktop` and `~/.local/bin/primebook-whitesur-session.sh`. XFCE runs this hook at every login, restoring WhiteSur selections on the live session bus after the settings daemon starts.
7. Writes GTK 3 fallback selections and Noto Sans typography to `~/.config/gtk-3.0/settings.ini`.
8. Persists Noto Sans desktop/window-title fonts and refreshes the WhiteSur icon cache.
9. Integrates the floating bottom-dock profile and app-finder shortcuts into the same XFCE login hook: the existing auto-hidden panel is shortened, icons enlarged, and Super+Space / Super+E launch compact / expanded app finder.
10. Restarts the existing Termux:X11/XFCE workflow using the repository's Stop All and Start All scripts.

The theme and icon assets remain user-local. The XFConf XML files, GTK settings file and XFCE autostart entry persist across logout, reboot and Termux:X11 relaunch; the login hook reapplies the selected values if XFCE restores stale settings. The script does not use the upstream GNOME theme-switcher, install GNOME Shell, replace XFCE panels, install Plank or Conky, enable Picom, or alter PRoot isolation, audio, CUPS or security configuration.

## Expected appearance

- WhiteSur Dark GTK 3/4 styling with blue accent and solid surfaces.
- Matching WhiteSur XFWM4 window decorations.
- WhiteSur dark icon theme.
- WhiteSur cursor theme.
- WhiteSur static wallpaper.
- Noto Sans desktop typography.
- Floating, auto-hidden bottom dock profile with larger icons and Spotlight-/Launchpad-style app finder shortcuts.
- Existing XFCE top panel, bottom panel plugins, launchers and applications retained; no panel items are deleted or reordered.

The icon theme's base/default color is used alongside the blue GTK accent; upstream WhiteSur icons do not provide a separate blue icon variant.

## Troubleshooting

If the desktop still looks unchanged after the script:
1. Confirm that the desktop was started using this repository's `start-all` command.
2. Open a Debian terminal as `prime` and inspect the saved settings:

   ```bash
   xfconf-query -c xsettings -p /Net/ThemeName
   xfconf-query -c xfwm4 -p /general/theme
   xfconf-query -c xsettings -p /Net/IconThemeName
   xfconf-query -c xsettings -p /Gtk/CursorThemeName
   ```

3. Confirm that the selected GTK theme directory exists under `~/.local/share/themes` and contains `gtk-3.0` and `xfwm4` subdirectories.
4. Check that `~/.config/autostart/primebook-whitesur.desktop` exists and that `~/.local/bin/primebook-whitesur-session.sh` is executable.
5. Check the XFCE session log and run `bash scripts/diagnose.sh` from Termux if the desktop fails to start.

Do not run the upstream GTK installer's GNOME Shell stages again merely to refresh XFCE.

## Rollback

The pre-WhiteSur XFCE configuration backup created during setup is stored at:

```text
~/.local/share/primebook-backups/xfce-before-whitesur-20261116-130152.tar.gz
```

To restore that backup, first stop the desktop with the repository's `stop-all` command. Then enter Debian as `prime` and extract the archive into the home directory:

```bash
tar -xzf ~/.local/share/primebook-backups/xfce-before-whitesur-20261116-130152.tar.gz -C "$HOME"
```

Restart the desktop with `start-all`. This restores the backed-up XFCE/GTK configuration and selections. It does not uninstall WhiteSur theme files or remove other themes, icons, applications or personal data.

## Scope boundaries

- No GNOME desktop or GNOME Shell extensions.
- No Plank, Conky or Picom installation.
- No system-wide theme installation.
- No changes to Termux:X11 startup, PRoot isolation/bindings, PulseAudio, CUPS or security hardening.
- No deletion of existing themes, icons, panels, launchers or user data.
