# Experimental Setup (MacOS)

Installation instructions for MacOS (Catalina 10.15.7)

## WARNING! THESE NOTES MAY BE INCORRECT/INCOMPLETE

See further:
 * [FOMU Toolchain](https://github.com/im-tomu/fomu-toolchain)
 * [TinyFPGA-BX User Guide](https://tinyfpga.com/bx/guide.html)
 * [learn-fpga toolchain](https://github.com/BrunoLevy/learn-fpga/blob/master/FemtoRV/TUTORIALS/toolchain.md)

## Fomu

The [Fomu](https://tomu.im/fomu.html) is a programmable/reconfigurable FPGA platform
that fits in a [USB](https://en.wikipedia.org/wiki/USB) Type-A port.

### Fomu Toolchain

Download and install the latest [Fomu Toolchain](https://github.com/im-tomu/fomu-toolchain).

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
$ cd $FOMU_PATH/riscv64-unknown-elf/bin
$ xattr -d com.apple.quarantine *
$ cd $FOMU_PATH/libexec/gcc/riscv64-unknown-elf/8.3.0
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
Note: [`Fomu/firmware`](Fomu/firmware) contains some `.dfu` snapshots.

```
$ dfu-util -D Fomu/firmware/pvt-updater-v2.0.3.dfu
$ dfu-util -l
dfu-util 0.9

Copyright 2005-2009 Weston Schmidt, Harald Welte and OpenMoko Inc.
Copyright 2010-2016 Tormod Volden and Stefan Schmidt
This program is Free Software and has ABSOLUTELY NO WARRANTY
Please report bugs to http://sourceforge.net/p/dfu-util/tickets/

Found DFU: [1209:5bf0] ver=0101, devnum=7, cfg=1, intf=0, path="20-2", alt=0, name="Fomu PVT running DFU Bootloader v2.0.3", serial="UNKNOWN"
```

### Fomu Programming Workshop

Install workshop files and submodules:
```
$ git clone --recurse-submodules https://github.com/im-tomu/fomu-workshop.git
```

The `wishbone-tool` can read/write arbitrary memory on the Fomu.
Since most things are controlled/accessed via memory-mapped registers,
this gives access to almost everything.

Useful addresses and register values can be found in the [Fomu Bootloader Documentation](https://rm.fomu.im/index.html).

#### Quick Reference

Reboot the Fomu (and reload default "breathing" program)
```
$ wishbone-tool 0xe0006000 0xac
```

## Icarus Verilog and GTKWave

 * [https://iverilog.fandom.com/wiki/User_Guide](https://iverilog.fandom.com/wiki/User_Guide)
 * [http://gtkwave.sourceforge.net/](http://gtkwave.sourceforge.net/)

```
$ brew install icarus-verilog
$ brew install gtkwave
$ xattr -d com.apple.quarantine /usr/local/bin/gtkwave
```

### Create and run simulation

```
$ iverilog -o test_bench.sim cnt_24MHz.v test_bench.v
$ ./test_bench.sim
```

Open the dumpfile `test_bench.vcd` with GTKWave to visualize waveforms.

## Synthesis, Place and Route

```
$ yosys -p 'synth_ice40 -json fomu_pvt.json' cnt_24MHz.v fomu_pvt.v
$ nextpnr-ice40 --up5k --package uwg30 --pcf ../Fomu/pcf/fomu-pvt.pcf --json fomu_pvt.json --asc fomu_pvt.asc
```

## DFU Packaging

```
$ icepack fomu_pvt.asc fomu_pvt.bit
$ cp fomu_pvt.bit fomu_pvt.dfu
$ dfu-suffix -v 1209 -p 70b1 -a fomu_pvt.dfu
```

Upload program to Fomu PVT
```
$ dfu-util -D fomu_pvt.dfu
```
