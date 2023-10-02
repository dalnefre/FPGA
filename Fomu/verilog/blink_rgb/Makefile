#
# Makefile
#

TOP	= blink_rgb
SRCS	= top.v

all: $(TOP).dfu

install: $(TOP).dfu
	dfu-util -D $<

clean:
	rm -f *.sim *.vcd *.json *.log *.asc *.bit *.dfu

%.sim: %.v %_tb.v
	iverilog -o $@ $^

%.vcd: %.sim
	./$<

$(TOP).json: $(SRCS)
	yosys -p 'synth_ice40 -json $@' $^ >$(TOP).log

%.asc: %.json
	nextpnr-ice40 --up5k --package uwg30 --pcf pins.pcf --json $< --asc $@

%.bit: %.asc
	icepack $< $@

%.dfu: %.bit
	cp $< $@
	dfu-suffix -v 1209 -p 70b1 -a $@

apio-verify:
	iverilog -B "/Users/dalnefre/.apio/packages/tools-oss-cad-suite/lib/ivl" -o hardware.out -D VCD_OUTPUT= -D NO_ICE40_DEFAULT_ASSIGNMENTS "/Users/dalnefre/.apio/packages/tools-oss-cad-suite/share/yosys/ice40/cells_sim.v" top.v

apio-build:
	yosys -p "synth_ice40 -json hardware.json" -q top.v
	nextpnr-ice40 --up5k --package uwg30 --json hardware.json --asc hardware.asc --pcf pins.pcf -q
	icepack hardware.asc hardware.bin

apio-upload:
	dfu-util -d 1209:5bf0 -a 0 -D hardware.bin
