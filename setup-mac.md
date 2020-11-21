# Experimental Setup (MacOS)

Installation instructions for MacOS (Catalina 10.15.7)

## FOMU

The [FOMU](https://tomu.im/fomu.html) is a programmable/reconfigurable FPGA platform
that fits in a [USB](https://en.wikipedia.org/wiki/USB) Type-A port.

### FOMU Toolchain

Download and install the latest [FOMU Toolchain](https://github.com/im-tomu/fomu-toolchain).

Edit shell configuration (e.g.: `~/.bash_profile`):
```
export FOMU_REV=pvt
export FOMU_PATH=$HOME/dev/fomu-toolchain-macos-v1.5.6
export GHDL_PREFIX=$FOMU_PATH/lib/ghdl
export PATH=$PATH:$FOMU_PATH/bin
```

Remove MacOS protection attribute from installed programs:
```
$ cd $FOMU_PATH/bin
$ xattr -d com.apple.quarantine *
```
**WARNING:** _Make sure you trust the source of a program before removing this attribute!_

To list registered USB devices:
```
$ ioreg -p IOUSB
+-o Root  <class IORegistryEntry, id 0x100000100, retain 17>
  +-o AppleUSBXHCI Root Hub Simulation@14000000  <class AppleUSBRootHubDevice, id 0x10000035d, registered, matched, active, busy 0 (0 ms), retain 13>
    +-o Bluetooth USB Host Controller@14300000  <class AppleUSBDevice, id 0x100008da7, registered, matched, active, busy 0 (0 ms), retain 21>
    +-o Fomu PVT running DFU Bootloader v2.0.3@14200000  <class AppleUSBDevice, id 0x10000ffa9, registered, matched, active, busy 0 (1 ms), retain 13>
```

#### Update the Bootloader

To list DFU-capable USB devices:
```
$ dfu-util -l
dfu-util 0.9

Copyright 2005-2009 Weston Schmidt, Harald Welte and OpenMoko Inc.
Copyright 2010-2016 Tormod Volden and Stefan Schmidt
This program is Free Software and has ABSOLUTELY NO WARRANTY
Please report bugs to http://sourceforge.net/p/dfu-util/tickets/

Found DFU: [1209:5bf0] ver=0101, devnum=6, cfg=1, intf=0, path="20-2", alt=0, name="Fomu PVT running DFU Bootloader v1.9.1", serial="UNKNOWN"
```

Get the latest [`foboot`](https://github.com/im-tomu/foboot/releases/latest) release.
Update according to [these instructions](https://workshop.fomu.im/en/latest/bootloader.html).
Note: `FOMU/firmware` contains some `.dfu` snapshots.

```
$ dfu-util -D FOMU/firmware/pvt-updater-v2.0.3.dfu
$ dfu-util -l
dfu-util 0.9

Copyright 2005-2009 Weston Schmidt, Harald Welte and OpenMoko Inc.
Copyright 2010-2016 Tormod Volden and Stefan Schmidt
This program is Free Software and has ABSOLUTELY NO WARRANTY
Please report bugs to http://sourceforge.net/p/dfu-util/tickets/

Found DFU: [1209:5bf0] ver=0101, devnum=7, cfg=1, intf=0, path="20-2", alt=0, name="Fomu PVT running DFU Bootloader v2.0.3", serial="UNKNOWN"
```

### FOMU Programming Workshop

Install workshop files and submodules:
```
$ git clone --recurse-submodules https://github.com/im-tomu/fomu-workshop.git
```
