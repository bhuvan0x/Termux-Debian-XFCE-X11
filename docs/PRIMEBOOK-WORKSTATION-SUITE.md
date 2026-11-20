# PrimeBook Workstation Suite

A user-space productivity and maintenance layer for Debian ARM64 under Termux/PRoot. It does not modify Android's kernel, boot chain, CPU governor, zram, firewall, or power policy.

## Install optional dependencies

Run from the Debian-side copy of this repository as root:

```bash
bash scripts/primebook-suite.sh install-tools
```

This installs `wmctrl`, `xrandr` utilities, `xclip`, XFCE Clipman, Tumbler and FFmpeg thumbnail support. It does not install a second desktop environment or heavyweight launcher.

## Commands

| Command | Purpose |
|---|---|
| `bash scripts/primebook-suite.sh health` | Read-only system and desktop health report |
| `bash scripts/primebook-suite.sh backup` | Create a configuration restore point |
| `bash scripts/primebook-suite.sh backup list` | List restore points |
| `bash scripts/primebook-suite.sh backup restore <archive>` | Restore selected configuration after confirmation |
| `bash scripts/primebook-suite.sh maintenance plan` | Simulate upgrades and autoremove |
| `bash scripts/primebook-suite.sh maintenance apply` | Apply upgrades and cleanup after explicit confirmation |
| `bash scripts/primebook-suite.sh tile left` | Tile active X11 window to the left half |
| `bash scripts/primebook-suite.sh tile right` | Tile active X11 window to the right half |
| `bash scripts/primebook-suite.sh tile top/bottom/center/maximize` | Other active-window layouts |

## Restore-point scope

Restore points live in `~/Backups/PrimeBook` with mode 0700 and adjacent SHA-256 checksums. The newest five are retained. Archives include selected XFCE, PrimeBook, autostart, Thunar and application-launcher configuration plus package-selection manifests. They are not full-system images and do not include personal documents, media, application databases, Android files or the Debian root filesystem. Package manifests are reference-only.

## Productivity integration

- **Window tiling:** test each `tile` command manually, then bind it in XFCE Settings > Keyboard > Application Shortcuts. Use the full Debian-side script path.
- **Clipboard history:** enable the Clipman panel plugin after installation. Clipboard history can contain passwords and private text; configure retention and clear it when appropriate.
- **Quick file previews:** Tumbler and FFmpeg thumbnailer add thumbnail support to Thunar. Enable previews in Thunar Preferences; supported formats vary.
- **Launcher:** retain XFCE App Finder (`Alt+F3`) rather than adding a second launcher process.
- **Screenshots:** use the existing XFCE Screenshot utility and configure its shortcut in XFCE Keyboard settings.

## Explicit platform limits

No CachyOS kernel/scheduler/zram/BBR/MGLRU/I/O-scheduler changes; no systemd timers or kernel OOM; no host firewall, AppArmor or auditd guarantee; no UEFI/Secure Boot/disk encryption/Btrfs root snapshots. ChromeOS Phone Hub parity, Android app streaming and notification mirroring are not available from a Debian PRoot guest alone. Android battery/radio integration requires a separately permissioned Termux-side implementation and real-device testing.
