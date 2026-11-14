# Installation guide

## 1. Install the Android applications

Install these Android apps from compatible sources. Termux and its add-ons must use matching signing keys.

- Termux: https://github.com/termux/termux-app
- Termux:X11: https://github.com/termux/termux-x11
- Termux:Widget: https://github.com/termux/termux-widget
- Termux:API: https://github.com/termux/termux-api

Install Termux:X11, Termux:Widget and Termux:API from the same release family/signing source as Termux. Open each Android add-on once after installation.

## 2. Clone the repository

~~~bash
pkg update && pkg upgrade -y
pkg install -y git
git clone https://github.com/bhuvan0x/Termux-Debian-X11.git
cd Termux-Debian-X11
chmod +x scripts/*.sh
~~~

## 3. Prepare Termux and create widget shortcuts

~~~bash
bash scripts/setup-termux.sh
~~~

This installs the Termux:X11 client, PulseAudio, proot-distro and the Termux:API command-line package (including termux-usb). It also creates launchers under ~/.shortcuts and background tasks under ~/.shortcuts/tasks.

If Termux:Widget is installed later, or you move the repository, regenerate its shortcuts:

~~~bash
bash scripts/install-termux-widget.sh
~~~

Then long-press the Android home screen, open **Widgets**, find **Termux:Widget**, and add it. The widget has exactly two everyday controls: **Start All** and **Stop All**.

## 4. Install Debian, XFCE, applications and printing

~~~bash
bash scripts/install-debian.sh
~~~

This installs Debian, XFCE, everyday GUI applications, CUPS, Epson ESC/P-R and Gutenprint drivers, USB diagnostics and scanner utilities. It creates the non-root desktop user prime, launchers under /home/prime/Desktop and the PrimeBook dark desktop styling.

For an existing Debian installation, run:

~~~bash
bash scripts/install-apps.sh
bash scripts/install-printing.sh
~~~

Optional office suite (large download and memory footprint):

~~~bash
bash scripts/install-apps.sh --office
~~~

**Your L3110:** the printer uses ESC/P-R, and SANE lists its scanner (USB ID 04b8:1142) as fully supported by the epson2 backend. The L3110 has USB 2.0 only; it does not have built-in Wi-Fi/Ethernet. Direct operation still requires USB visibility through Android/PRoot. Details are in USB-AND-PRINTING.md.

## 5. Check USB devices and X11 input

With a USB OTG device attached:

~~~bash
bash scripts/check-usb.sh
~~~

The script lists devices Android exposes to Termux:API, checks Debian's USB view, and (when X11 is running) lists XInput devices using xinput list.

To request Android permission for a listed USB device:

~~~bash
bash scripts/check-usb.sh --request /dev/bus/usb/001/002
~~~

Replace the example path with the exact path printed by termux-usb -l.

Android handles normal USB keyboards/mice as input devices and Termux:X11 receives the resulting input events. Raw USB access is different: PRoot does not automatically receive arbitrary Android USB device nodes or the USB file descriptor. The permission prompt does not guarantee that Linux printer/scanner backends can operate the USB device. See USB-AND-PRINTING.md.

## 6. Start the desktop and CUPS

Open the Termux:X11 Android app once after installing it. From the repository directory, use the single start command:

~~~bash
bash scripts/start-all.sh
~~~

This starts Termux:X11, localhost-only PulseAudio forwarding, CUPS (if installed) and XFCE as unprivileged user prime. You do not need to start the desktop and printer services separately.

Open CUPS in the Debian browser:

~~~text
http://127.0.0.1:631
~~~

Before administering printers, set a password for the prime desktop account from Termux:

~~~bash
proot-distro login debian -- passwd prime
~~~

In CUPS, use **Administration → Add Printer**. For the L3110, direct USB printing works only if Android exposes the raw USB device to PRoot. The L3110 itself has no Wi-Fi/Ethernet. If PRoot cannot access USB, connect the printer to a separate Linux host and share that host's CUPS queue over IPP.

## 7. Stop and update

~~~bash
bash scripts/stop-all.sh
bash scripts/update-debian.sh
~~~

Stop All shuts down XFCE, CUPS, the Termux:X11 server and PulseAudio together.

## 8. Optional developer tools

Inside Debian:

~~~bash
apt install -y neovim tmux clang cmake ninja-build gdb \
  nodejs npm default-jdk golang rustc cargo
~~~

Install only the toolchains you use; large language runtimes and IDEs can consume substantial storage and RAM.

## Notes and limitations

- This is Debian userspace under PRoot, not a virtual machine or a second kernel.
- Android remains the host OS and controls hardware, kernel features, power management and background process lifetime.
- systemd services, kernel modules, Docker-style nested containers and some low-level networking or hardware features are not expected to work like a conventional Linux PC.
- Firefox and VLC run under the non-root prime account. Do not start XFCE as root.
- USB HID input can be forwarded by Android to the foreground X11 app, but generic USB printer/scanner passthrough is not provided by PRoot.
- Performance depends on the PrimeBook's RAM, thermal limits, Android build and Termux:X11 version.
