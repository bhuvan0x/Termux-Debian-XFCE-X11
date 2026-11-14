# USB devices and Epson printing

## USB visibility has three layers

1. **Android** enumerates devices connected in USB host/OTG mode and controls app permission.
2. **Termux:API** can list USB devices and request Android permission. Its termux-usb command can pass a USB file descriptor to a specially written program.
3. **Debian inside PRoot** is not automatically given access to Android's raw USB device nodes. A permission grant to Termux does not automatically pass the device into CUPS, SANE or every Linux application.

Run this from the repository directory in Termux:

~~~bash
bash scripts/check-usb.sh
~~~

To ask Android for permission for a listed USB device:

~~~bash
bash scripts/check-usb.sh --request /dev/bus/usb/001/002
~~~

The path above is only an example. Use the exact path printed by the USB list. Android may display a permission dialog.

Install both parts of Termux:API:

- Termux command-line package: setup-termux.sh installs the termux-api package.
- Separate Android add-on: https://github.com/termux/termux-api

The Termux:API APK must be signed compatibly with the installed Termux app.

## USB keyboards, mice and HID devices

Standard USB keyboards and mice connected in Android host/OTG mode are normally handled by Android's input stack. Termux:X11 can receive the mapped input events when its window has focus. This is different from giving Debian raw access to the USB device.

With the X11 desktop running, check:

~~~bash
bash scripts/check-usb.sh
~~~

Inspect the **Input devices visible through the active X11 display** section. It runs xinput list against display :0. Some physical devices may be represented by a virtual Termux:X11 input device instead of their own physical USB name. Test typing, pointer movement, right-click and scrolling in an XFCE application.

Specialized hardware such as serial adapters, microcontrollers, SDRs, smart-card readers, capture cards, printers and scanners may require a device-specific Termux program that consumes the file descriptor passed by termux-usb -e. Generic Linux USB drivers inside PRoot cannot simply open the Android device path.

## USB storage

Plug the drive into Android, allow Android to mount it, and expose it through Termux shared storage if Debian needs its files. Do not expect to mount a raw block device from inside the PRoot environment.

## Epson printer drivers included

The default printing installer adds:

- **CUPS** — print queues and printer management.
- **printer-driver-escpr** — Epson ESC/P-R driver for Epson models that implement that print language.
- **printer-driver-gutenprint** — additional CUPS drivers for many printer models, including some Epson devices.
- **usbutils and sane-utils** — USB and scanner diagnostics. sane-airscan is installed when available for network scanner discovery.

There is no single Linux driver guaranteed to work with every Epson printer. ESC/P-R is used by selected Epson inkjet models. Gutenprint also has a finite supported-model list. Check the exact model in the driver documentation or Epson support pages before assuming compatibility.

Debian provides both driver packages for ARM64:

- Debian ESC/P-R package: https://packages.debian.org/trixie/arm64/printer-driver-escpr
- Debian Gutenprint package: https://packages.debian.org/trixie/arm64/printer-driver-gutenprint
- Epson ESC/P-R manual: https://download.ebz.epson.net/man/linux/escpr.html

## Install and start printing

Fresh installations include printing support. For an existing Debian installation:

~~~bash
bash scripts/install-printing.sh
bash scripts/start-printing.sh
~~~

Open the CUPS administration page in the Debian browser:

~~~text
http://127.0.0.1:631
~~~

Before administering printers, set a password for the Debian desktop user from Termux:

~~~bash
proot-distro login debian -- passwd prime
~~~

Then use CUPS **Administration → Add Printer**. The installer adds the prime user to the CUPS lpadmin group.

## Recommended printer connection: Wi-Fi or Ethernet

For this Android + PRoot configuration, connect the Epson printer to the same Wi-Fi/Ethernet network as the PrimeBook. Add it in CUPS by IPP/IPPS or its network address. This avoids the Android/PRoot raw USB device-node restriction.

If the printer supports driverless IPP Everywhere or AirPrint, try that option first. Otherwise choose the detected ESC/P-R or Gutenprint model that exactly matches the printer.

## Direct USB printing caveat

The package installer includes USB-related CUPS drivers, but this does not make USB printing work automatically. PRoot cannot generally hand CUPS a raw Android USB device node. Termux:API can obtain a USB file descriptor for a custom program, but CUPS's normal USB backend is not wired to that descriptor by this project.

Direct USB printing would require an Android-side USB bridge/backend designed for the exact printer protocol. This repository does not claim to implement that bridge.

## Stop CUPS

~~~bash
bash scripts/stop-printing.sh
~~~

## Troubleshooting

- **Android USB list is empty:** check USB OTG/host mode, cable, hub power and Android's USB permission prompt.
- **termux-usb is missing:** run pkg install termux-api and install/open the separate Termux:API Android add-on.
- **XInput does not show a physical device name:** Android may expose inputs through a virtual Termux:X11 device; test keyboard and mouse behavior in XFCE.
- **CUPS page does not load:** run bash scripts/start-printing.sh and inspect /var/log/cups/error_log inside Debian.
- **Printer not found on network:** confirm both devices are on the same LAN, try the printer's IP address and check that the router does not isolate wireless clients.
- **Epson model is not listed:** supply the exact printer model and Debian release so the correct ESC/P-R, Gutenprint, Epson-specific or driverless route can be checked.
