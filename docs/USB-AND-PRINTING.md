# Epson EcoTank L3110: USB printing and scanning

## Confirmed model details

The EcoTank L3110 is a USB 2.0 multifunction printer. Unlike the L3150, Epson's specification lists no built-in Wi-Fi or Ethernet for the L3110. It uses Epson ESC/P-R for printing. Sources:

- Epson L3110 official product page: https://www.epson.co.in/For-Home/Printers/EcoTank-Printers/EcoTank-L3110-Multifunction-InkTank-Printer/p/C11CG87504
- Epson L3110/L3150 specification table (the models have different connectivity): https://mediaserver.goepson.com/ImConvServlet/imconv/e8815d81fe9b79ad95ab6f79d819b53b9083bfc2/original?assetDescr=Epson+L3110+L3150.pdf

SANE's supported-device list explicitly lists the **L3110 Series** with USB ID **04b8:1142**, status **Complete**, backend **epson2**. That is a model-specific scanner match, not a generic guess:

- SANE supported devices: https://www.sane-project.org/sane-mfgs.html

## Printing driver

The Debian setup installs CUPS and an L3110-aware ARM64 build of `printer-driver-escpr`. The stock Debian 13/Trixie version 1.7.17 does not include the L3110 model PPD; Debian's 1.8.8 ARM64 package does include `Epson-L3110_Series-epson-escpr-en.ppd`. The installer temporarily adds Debian Forky with a pin applying only to `printer-driver-escpr`, installs the newer package, and removes the temporary source and pin. It does not leave your system tracking Forky. Epson's current Linux download entry for this model is an `amd64` .deb, which must not be installed on this ARM64 Debian rootfs.

- Debian Trixie ESC/P-R package: https://packages.debian.org/trixie/arm64/printer-driver-escpr
- Debian ARM64 1.8.8 package with L3110 PPD: https://packages.debian.org/forky/arm64/printer-driver-escpr
- Debian 1.8.8 L3110 PPD file list: https://sources.debian.org/src/epson-inkjet-printer-escpr/1.8.8-1/ppd/
- Epson's L3110 Linux download entry (Deb x64): https://download-center.epson.com/download/?device_id=L3110+Series&language=en&module_id=942262ec-5a61-482b-ae9c-3cd08f07584d%3A1.8.6&os=DEBX64&region=MN
- Epson L3110 specifications: https://mediaserver.goepson.com/ImConvServlet/imconv/8cfeb3a65688824f46aadec9c4bc312118f007b9/original?assetDescr=Epson%2520L3110%2520L3150.pdf

The installer includes Gutenprint as an additional driver set. The ESC/P-R 1.8.8 model database is the source of the exact L3110 Series PPD.

## Scanner driver

The installer includes SANE's runtime and CLI tools, and Simple Scan when available in the Debian repository. The L3110 is supported by SANE's `epson2` backend. The scanner USB ID is `04b8:1142`.

After installation, connect the printer's USB cable to the PrimeBook (using a data-capable OTG adapter/hub), then run in Debian:

~~~bash
scanimage -L
~~~

Expected device discovery should identify an Epson scanner. If it reports no scanners, that does not invalidate the SANE driver match: first check whether Android sees the device and whether PRoot can access the raw USB bus.

For a scan test (once the scanner is actually visible):

~~~bash
scanimage --format=pnm > ~/scan-test.pnm
~~~

For a GUI, launch **Document Scanner** (Simple Scan) from the Debian desktop menu/shortcut when it is installed.

## USB limitation on Android + PRoot

There are separate layers:

1. Android enumerates the L3110 over USB host/OTG and asks the user to grant an app permission.
2. Termux:API's `termux-usb` can list devices and request permission. It can hand a USB file descriptor to a specially written Termux program.
3. Debian in PRoot does not automatically get general access to Android's USB device nodes. Granting Termux permission does not automatically connect CUPS's USB backend or SANE's `epson2` backend to the printer/scanner.

Run diagnostics in Termux:

~~~bash
bash scripts/check-usb.sh
~~~

That command reports Android's USB inventory, Debian's `/dev/bus/usb` visibility, SANE `scanimage -L`, and XInput devices (when X11 is running). To request Android permission, use the exact path reported by `termux-usb -l`:

~~~bash
bash scripts/check-usb.sh --request /dev/bus/usb/001/002
~~~

The example device path is not literal; copy the path from your device output. A permission grant alone does not create PRoot passthrough.

## Ways to use this L3110 with the PrimeBook

**Option A — direct USB inside Debian:** This is the desired simple workflow, but it only works if the Android/PRoot environment exposes a usable USB device node to CUPS/SANE. The repository now checks for that. It cannot force Android to expose the hardware.

**Option B — use a separate Linux host as a print/scan server:** Connect the L3110 by USB to a Raspberry Pi, Linux mini-PC, or another always-on computer. Run CUPS and SANE on that host, and share printing over IPP. For scanning, configure a SANE network frontend/backend or another scanner-sharing service on the host. This is not built into this repository, but it bypasses the PrimeBook's PRoot USB restriction.

**Option C — USB-over-network hardware:** A USB device server may share the USB device over the LAN, but check that it supports multifunction printer scanner interfaces and Linux clients; generic USB print servers sometimes support printing only, not scanning.

Do not expect the L3110 itself to join Wi-Fi. Epson's spec distinguishes the L3110 (USB only) from L3150 (Wi-Fi).

## Install or re-run support

Fresh repository installations add this stack automatically. To add it to an existing Debian installation, run this one-time setup command:

~~~bash
bash scripts/install-printing.sh
~~~

After installation, use the normal daily command `start-all`; CUPS starts with the desktop. The installer creates **Epson L3110 Series Setup** on `/home/prime/Desktop` and in the XFCE Applications menu. Open it to reach the CUPS Administration page, then choose **Add Printer** and select the Epson L3110 Series driver when it appears.

You can also open CUPS directly in the Debian browser:

~~~text
http://127.0.0.1:631/admin
~~~

To verify the driver package, model entries, CUPS state, USB visibility and scanner detection from Termux, run:

~~~bash
bash scripts/check-epson-l3110.sh
~~~

Set a password for the `prime` account in Termux before CUPS administration:

~~~bash
proot-distro login debian -- passwd prime
~~~

The installer adds `prime` to CUPS/scanner groups where those groups exist.

## Stop CUPS

~~~bash
bash scripts/stop-all.sh
~~~

Stop All also shuts down XFCE, Termux:X11 and PulseAudio.
