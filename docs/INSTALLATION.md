# Installation guide

## 1. Install the Android applications

Install these Android apps from compatible sources. Termux and its add-ons must use matching signing keys.

- Termux: https://github.com/termux/termux-app
- Termux:X11: https://github.com/termux/termux-x11
- Termux:Widget: https://github.com/termux/termux-widget
- Termux:API: https://github.com/termux/termux-api

Install Termux:X11, Termux:Widget and Termux:API from the same release family/signing source as Termux. Open each Android add-on once after installation.

## 2. Clone the repository

This project repository is private. Authenticate with GitHub CLI using the browser login flow; never paste a personal access token into chat or commit one to the repository.

```bash
pkg update && pkg upgrade -y
pkg install -y git gh
gh auth login
gh auth setup-git
gh repo clone bhuvan0x/Termux-Debian-X11
cd Termux-Debian-X11
```

The setup script configures repository-local `core.filemode=false`. This prevents Android executable-bit-only differences from blocking future pulls. Scripts are invoked through `bash`, so you do not need to run `chmod +x scripts/*.sh`.

If a previous local chmod has already blocked the first pull, inspect:

```bash
git diff --summary
```

If the output contains only mode changes such as `100644 => 100755`, restore those mode-only changes once and then pull:

```bash
git restore scripts/*.sh
git pull --ff-only
git config core.filemode false
```

Do not use `git reset --hard` for this.

## 3. Prepare Termux and create shortcuts

```bash
bash scripts/setup-termux.sh
```

This installs the Termux:X11 client, PulseAudio, proot-distro and the Termux:API command-line package (including termux-usb). It also:

- Configures Git to ignore executable-bit-only changes in this clone.
- Creates Termux terminal commands `start-all` and `stop-all` in `$PREFIX/bin`.
- Creates launchers under `~/.shortcuts` and background tasks under `~/.shortcuts/tasks`.

If Termux:Widget is installed later, or you move the repository, regenerate its shortcuts:

```bash
bash scripts/install-termux-widget.sh
```

Then long-press the Android home screen, open **Widgets**, find **Termux:Widget**, and add it. The widget has exactly two everyday controls: **Start All** and **Stop All**.

## 4. Install Debian, XFCE, applications and printing

```bash
bash scripts/install-debian.sh
```

This installs Debian, XFCE, everyday GUI applications (including GDebi), CUPS, Epson ESC/P-R and Gutenprint drivers, USB diagnostics and scanner utilities. It creates the non-root desktop user `prime`, a password-authenticated sudoers rule for `prime`, launchers under `/home/prime/Desktop` and the PrimeBook dark desktop styling.

For an existing Debian installation, run:

```bash
bash scripts/install-apps.sh
bash scripts/install-printing.sh
```

To install a local Debian package and let GDebi resolve its dependencies, use a Debian terminal as `prime`:

```bash
sudo gdebi /path/to/package.deb
```

Check the package architecture first with `dpkg-deb -f /path/to/package.deb Architecture`. This device's Debian environment is ARM64; GDebi does not convert `amd64` packages to ARM64. For an existing installation, pull the repository update and rerun `bash scripts/install-apps.sh` to add GDebi.

Optional office suite (large download and memory footprint):

```bash
bash scripts/install-apps.sh --office
```

**Your L3110:** the printer uses ESC/P-R, and SANE lists its scanner (USB ID 04b8:1142) as fully supported by the epson2 backend. The L3110 has USB 2.0 only; it does not have built-in Wi-Fi/Ethernet. Direct operation still requires USB visibility through Android/PRoot. Details are in USB-AND-PRINTING.md.

## 5. Configure Debian sudo access if needed

The desktop user `prime` is unprivileged. The app installer creates a dedicated password-authenticated sudoers drop-in. If `sudo` still reports that `prime` is not in the sudoers file, reapply the desktop app setup with `bash scripts/install-apps.sh`, or create the rule manually from Termux (Termux enters Debian as root):

```bash
proot-distro login debian -- bash -lc 'printf "%s\n" "prime ALL=(ALL:ALL) ALL" > /etc/sudoers.d/prime && chmod 0440 /etc/sudoers.d/prime && visudo -c'
```

The rule requires the `prime` password; it does not grant passwordless sudo. Set or change the Debian password without putting it in a script or repository:

```bash
proot-distro login debian -- passwd prime
```

After changing group membership, fully stop and restart XFCE so the new session receives updated groups.

## 6. Check USB devices and X11 input

With a USB OTG device attached:

```bash
bash scripts/check-usb.sh
```

The script lists devices Android exposes to Termux:API, checks Debian's USB view, and (when X11 is running) lists XInput devices using xinput list.

To request Android permission for a listed USB device:

```bash
bash scripts/check-usb.sh --request /dev/bus/usb/001/002
```

Replace the example path with the exact path printed by termux-usb -l.

Android handles normal USB keyboards/mice as input devices and Termux:X11 receives the resulting input events. Raw USB access is different: PRoot does not automatically receive arbitrary Android USB device nodes or the USB file descriptor. The permission prompt does not guarantee that Linux printer/scanner backends can operate the USB device. See USB-AND-PRINTING.md.

## 7. Start the desktop and CUPS

Open the Termux:X11 Android app once after installing it. From any Termux directory, use:

```bash
start-all
```

Equivalent script command:

```bash
bash scripts/start-all.sh
```

Start All launches the Termux-side PulseAudio server, checks and loads its localhost-only TCP audio module once, verifies Debian's audio connection, starts the Termux:X11 server/viewer, starts CUPS (if installed) and runs XFCE as unprivileged user `prime`.

Use a second Termux session, the Stop All widget, or:

```bash
stop-all
```

Stop All closes the Termux:X11 Android viewer using its stop broadcast, terminates the X11 server, stops CUPS and PulseAudio, and exits XFCE. The Start All session remains occupied while XFCE runs.

Open CUPS in the Debian browser:

```text
http://127.0.0.1:631
```

Before administering printers, set a password for the prime desktop account from Termux:

```bash
proot-distro login debian -- passwd prime
```

In CUPS, use **Administration → Add Printer**. For the L3110, direct USB printing works only if Android exposes the raw USB device to PRoot. The L3110 itself has no Wi-Fi/Ethernet. If PRoot cannot access USB, connect the printer to a separate Linux host and share that host's CUPS queue over IPP.

## 8. Install Visual Studio Code (optional)

For this ARM64 Debian environment, run the repository installer from Termux:

```bash
bash scripts/install-vscode.sh
```

It downloads Microsoft's official stable ARM64 Debian package, checks that the package architecture is `arm64`, installs it and creates a per-user XFCE launcher for `prime`.

The launcher uses `--no-sandbox --disable-gpu` because Chromium/Electron sandboxing and GPU acceleration can fail under PRoot/Termux:X11. The `--no-sandbox` flag weakens renderer isolation; this workaround is intended only for this trusted local PRoot desktop. Do not download or install an `amd64` package on ARM64.

The VS Code keyring prompt is separate from installation. You can cancel it and use the editor, but secure credential storage and sign-in may need GNOME Keyring setup later.

## 9. Update

```bash
cd ~/Termux-Debian-X11
git pull --ff-only
```

The repository-local Git setting prevents executable-bit-only changes from blocking this pull. No `chmod +x` step is required.

Update Debian packages separately:

```bash
bash scripts/update-debian.sh
```

## Notes and limitations

- This is Debian userspace under PRoot, not a virtual machine or a second kernel.
- Android remains the host OS and controls hardware, kernel features, power management and background process lifetime.
- systemd services, kernel modules, Docker-style nested containers and some low-level networking or hardware features are not expected to work like a conventional Linux PC.
- Firefox, VLC and VS Code run under the non-root `prime` account. Do not start XFCE as root.
- USB HID input can be forwarded by Android to the foreground X11 app, but generic USB printer/scanner passthrough is not provided by PRoot.
- Performance depends on the PrimeBook's RAM, thermal limits, Android build and Termux:X11 version.
