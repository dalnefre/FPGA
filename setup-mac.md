# Experimental Setup (MacOS)

Installation instructions for MacOS (Catalina 10.15.7)

## FOMU

The [FOMU](https://tomu.im/fomu.html) is a programmable/reconfigurable FPGA platform
that fits in a [USB](https://en.wikipedia.org/wiki/USB) Type-A port.

### FOMU Toolchain

Download and install the latest [FOMU Toolchain](https://github.com/im-tomu/fomu-toolchain).

Edit shell configuration (e.g.: `~/.bash_profile`):
```
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

Found DFU: [1209:5bf0] ver=0101, devnum=6, cfg=1, intf=0, path="1-1.1.3", alt=0, name="Fomu PVT running DFU Bootloader v1.9.1", serial="UNKNOWN"
```

Get the latest [`foboot`](https://github.com/im-tomu/foboot/releases/latest) release.
Update according to [these instructions](https://workshop.fomu.im/en/latest/bootloader.html).
Note: `FOMU/firmware` contains some `.dfu` snapshots.

```
$ wget https://github.com/im-tomu/foboot/releases/download/v2.0.3/pvt-updater-v2.0.3.dfu
$ dfu-util -D pvt-updater-v2.0.3.dfu
$ dfu-util -l
dfu-util 0.9

Copyright 2005-2009 Weston Schmidt, Harald Welte and OpenMoko Inc.
Copyright 2010-2016 Tormod Volden and Stefan Schmidt
This program is Free Software and has ABSOLUTELY NO WARRANTY
Please report bugs to http://sourceforge.net/p/dfu-util/tickets/

Found DFU: [1209:5bf0] ver=0101, devnum=7, cfg=1, intf=0, path="1-1.1.3", alt=0, name="Fomu PVT running DFU Bootloader v2.0.3", serial="UNKNOWN"
```

### FOMU Programming Workshop

Install workshop files and submodules:
```
$ git clone --recurse-submodules https://github.com/im-tomu/fomu-workshop.git
```
