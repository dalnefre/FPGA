# Experimental Setup (Raspberry Pi 3/4)

## WARNING! THESE NOTES MAY BE INCORRECT/INCOMPLETE

See further:
 * [FOMU Toolchain](https://github.com/im-tomu/fomu-toolchain)
 * [TinyFPGA-BX User Guide](https://tinyfpga.com/bx/guide.html)
 * [learn-fpga toolchain](https://github.com/BrunoLevy/learn-fpga/blob/master/FemtoRV/TUTORIALS/toolchain.md)

## Fomu

The [Fomu](https://tomu.im/fomu.html) is a programmable/reconfigurable FPGA platform
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

The Fomu shows up as `ID 1209:5bf0 Generic` (the rest are standard RPi3-B+ devices).

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

## TinyFPGA-BX

The [TinyFPGA boards](https://tinyfpga.com/) are a series
of low-cost, [open-source](https://github.com/tinyfpga) FPGA boards in a tiny form factor.

The TinyFPGA-BX [User Guide](https://tinyfpga.com/bx/guide.html)
described how to install and setup
the tools required for FPGA development.

Here's a summary of steps taken on a Raspberry Pi4:
```
$ sudo usermod -a -G dialout $USER
$ pip install --upgrade pip
$ pip install apio==0.4.0b5 tinyprog
WARNING: pip is being invoked by an old script wrapper. This will fail in a future version of pip.
Please see https://github.com/pypa/pip/issues/5599 for advice on fixing the underlying issue.
To avoid this problem you can invoke Python with '-m pip' instead of running pip directly.
DEPRECATION: Python 2.7 reached the end of its life on January 1st, 2020. Please upgrade your Python as Python 2.7 is no longer maintained. pip 21.0 will drop support for Python 2.7 in January 2021. More details about Python 2 support in pip can be found at https://pip.pypa.io/en/latest/development/release-process/#python-2-support pip 21.0 will remove support for this functionality.
Defaulting to user installation because normal site-packages is not writeable
...
Successfully built apio pyusb jsonmerge functools32 pyrsistent scandir
Installing collected packages: click, semantic-version, apio, pyparsing, packaging, pyusb, functools32, attrs, pyrsistent, contextlib2, zipp, configparser, scandir, pathlib2, importlib-metadata, jsonschema, jsonmerge, tqdm, intelhex, tinyprog
  WARNING: The script apio is installed in '/home/pi/.local/bin' which is not on PATH.
  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.
  WARNING: The script jsonschema is installed in '/home/pi/.local/bin' which is not on PATH.
  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.
  WARNING: The script tqdm is installed in '/home/pi/.local/bin' which is not on PATH.
  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.
  WARNING: The script tinyprog is installed in '/home/pi/.local/bin' which is not on PATH.
  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.
Successfully installed apio-0.4.0b5 attrs-20.3.0 click-6.7 configparser-4.0.2 contextlib2-0.6.0.post1 functools32-3.2.3.post2 importlib-metadata-2.1.1 intelhex-2.3.0 jsonmerge-1.7.0 jsonschema-3.2.0 packaging-20.8 pathlib2-2.3.5 pyparsing-2.4.7 pyrsistent-0.16.1 pyusb-1.1.0 scandir-1.10.0 semantic-version-2.8.5 tinyprog-1.0.23 tqdm-4.55.1 zipp-1.2.0
$ apio install system scons icestorm iverilog
$ apio drivers --serial-enable
```
