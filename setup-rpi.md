# Experimental Setup (Raspberry Pi 3/4)

## FOMU

The [FOMU](https://tomu.im/fomu.html) is a programmable/reconfigurable FPGA platform
that fits in a [USB](https://en.wikipedia.org/wiki/USB) Type-A port.

To list currently-installed USB devices:
```
$ lsusb
Bus 001 Device 006: ID 1209:5bf0 Generic 
Bus 001 Device 005: ID 0424:7800 Standard Microsystems Corp. 
Bus 001 Device 003: ID 0424:2514 Standard Microsystems Corp. USB 2.0 Hub
Bus 001 Device 002: ID 0424:2514 Standard Microsystems Corp. USB 2.0 Hub
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
```

The FOMU shows up as `ID 1209:5bf0 Generic` (the rest are standard RPi3-B+ devices).

### USB DFU

[USB DFU](http://wiki.openmoko.org/wiki/USB_DFU_-_The_USB_Device_Firmware_Upgrade_standard)
is the **USB** **D**evice **F**irmware **U**pgrade standard.

[`dfu-util`](http://wiki.openmoko.org/wiki/Dfu-util)
is a program that implements the Host (PC) side of the USB DFU protocol.
You can [read the manual](http://wiki.openmoko.org/wiki/Manuals/Dfu-util).

There is a SourceForge site for [`dfu-util`](http://dfu-util.sourceforge.net/).
Including a [manual page](http://dfu-util.sourceforge.net/dfu-util.1.html).

#### Install on Debian (Raspberry Pi OS):

```
$ sudo apt install dfu-util
```

To list DFU-capable USB devices:
```
$ sudo dfu-util -l
dfu-util 0.9

Copyright 2005-2009 Weston Schmidt, Harald Welte and OpenMoko Inc.
Copyright 2010-2016 Tormod Volden and Stefan Schmidt
This program is Free Software and has ABSOLUTELY NO WARRANTY
Please report bugs to http://sourceforge.net/p/dfu-util/tickets/

Found DFU: [1209:5bf0] ver=0101, devnum=6, cfg=1, intf=0, path="1-1.1.3", alt=0, name="Fomu PVT running DFU Bootloader v1.9.1", serial="UNKNOWN"
```

#### Update the Bootloader

Get the latest [`foboot`](https://github.com/im-tomu/foboot/releases/latest) release.
Update according to [these instructions](https://workshop.fomu.im/en/latest/bootloader.html).

```
$ wget https://github.com/im-tomu/foboot/releases/download/v2.0.3/pvt-updater-v2.0.3.dfu
$ sudo dfu-util -D pvt-updater-v2.0.3.dfu
$ sudo dfu-util -l
dfu-util 0.9

Copyright 2005-2009 Weston Schmidt, Harald Welte and OpenMoko Inc.
Copyright 2010-2016 Tormod Volden and Stefan Schmidt
This program is Free Software and has ABSOLUTELY NO WARRANTY
Please report bugs to http://sourceforge.net/p/dfu-util/tickets/

Found DFU: [1209:5bf0] ver=0101, devnum=7, cfg=1, intf=0, path="1-1.1.3", alt=0, name="Fomu PVT running DFU Bootloader v2.0.3", serial="UNKNOWN"
```

#### Mount the `usbfs` (optional?)

According to the folks at Openmoko,
to run `dfu-util`, you need to have `/proc/bus/usb` mounted and working.

To mount for just the current session:
```
$ sudo mount -t usbfs usbfs /proc/bus/usb
```

To automatically mount on each reboot, edit `/etc/fstab` and add:
```
usbfs   /proc/bus/usb   usbfs   defaults
```

To list USB devices:
```
$ sudo ls /proc/bus/usb
```
