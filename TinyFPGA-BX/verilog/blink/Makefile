#
# Makefile
#

TOP	= blink
SRCS	= top.v

all: $(TOP).bin

install: $(TOP).bin
	tinyprog --pyserial --program $<

clean:
	rm -f $(ALL) *.sim *.vcd *.json *.log *.asc *.bin

%.sim: %.v %_tb.v
	iverilog -o $@ $^

%.vcd: %.sim
	./$<

$(TOP).json: $(SRCS)
	yosys -p 'synth_ice40 -json $@' $^ >$(TOP).log

%.asc: %.json
	nextpnr-ice40 --lp8k --package cm81 --pcf pins.pcf --json $< --asc $@

%.bin: %.asc
	icepack $< $@

apio-verify:
	iverilog -B "/Users/dalnefre/.apio/packages/tools-oss-cad-suite/lib/ivl" -o hardware.out -D VCD_OUTPUT= -D NO_ICE40_DEFAULT_ASSIGNMENTS "/Users/dalnefre/.apio/packages/tools-oss-cad-suite/share/yosys/ice40/cells_sim.v" top.v

apio-build:
	yosys -p "synth_ice40 -json hardware.json" -q top.v
	nextpnr-ice40 --lp8k --package cm81 --json hardware.json --asc hardware.asc --pcf pins.pcf -q
	icepack hardware.asc hardware.bin

apio-upload:
	tinyprog --pyserial --program hardware.bin
