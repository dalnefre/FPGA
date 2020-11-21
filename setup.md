# Experimental Setup

## FOMU

[FOMU](https://tomu.im/fomu.html) is a programmable/reconfigurable FPGA platform
that fits in a [USB](https://en.wikipedia.org/wiki/USB) Type-A port.

To list currently-installed USB devices:
```
$ lsusb
```

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
