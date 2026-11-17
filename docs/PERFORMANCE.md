# Debian PRoot performance profile

This profile targets the actual execution model used here: Debian ARM64 inside Termux PRoot, displayed through Termux:X11 with XFCE. It deliberately changes only two live, per-user XFCE settings.

## Apply FAST mode

Run from Termux while the XFCE desktop is running:

```bash
cd ~/Termux-Debian-X11
bash scripts/performance.sh status
bash scripts/performance.sh fast
```

FAST mode:
- Disables the XFCE window-manager compositor. This can reduce extra rendering work and improve responsiveness on devices where compositing is the bottleneck.
- Disables GTK animations.
- Does not change wallpaper selection, Fresco, panel layout, theme, application launchers, audio, CUPS, PRoot isolation or Android settings.
- Saves the two original values in `/home/prime/.config/primebook/performance-original.conf` before the first change.

The compositor change is reversible but has a visual trade-off: shadows, transparency and other composited effects may disappear. If a wallpaper layer or another visual feature behaves worse, restore the original profile.

## Restore

```bash
bash scripts/performance.sh restore
```

The restore action reapplies the values captured before the first FAST run and removes the saved state file. Re-running FAST does not overwrite the original snapshot.

## Important PRoot limits

Debian PRoot shares the Android kernel. A Debian process cannot independently tune the host kernel's CPU scheduler, I/O scheduler, `vm.swappiness`, zram, GPU driver, CPU governor, thermal policy or Android memory management. Attempts to write those settings from Debian would be ineffective or inappropriate. Those controls belong to Android/host configuration and are intentionally not included here.

This project also does not blindly disable system services, remove packages, purge caches, change process priorities, or force GPU flags. Such changes can break D-Bus, audio, printing, Fresco, browser rendering or desktop startup without delivering measurable gains.

## Measure before adding more tweaks

For a meaningful comparison, test the same workload before and after FAST mode:
1. Start the desktop with `start-all`.
2. Open the same apps and windows.
3. Compare window movement, app launch time, scrolling and video playback.
4. Check Android temperature and battery state; thermal throttling can dominate performance.
5. If FAST mode causes visual regressions, run the restore command.

The profile is a safe baseline, not a claim that every device will become faster. If the compositor was not the bottleneck, the improvement may be small or unnoticeable.
