#
# Makefile
#

TOP	= uart
MODS	= serial_tx.v

all: $(TOP).dfu

install: $(TOP).dfu
	tinyprog --pyserial --program $<

clean:
	rm -f *.sim *.vcd *.json *.log *.asc *.bin

%.sim: $(MODS) %_tb.v
	iverilog -o $@ $^

%.vcd: %.sim
	./$<

$(TOP).json: $(MODS) top.v
	yosys -p 'synth_ice40 -json $@' $^ >$(TOP).log

%.asc: %.json
	nextpnr-ice40 --lp8k --package cm81 --pcf pins.pcf --json $< --asc $@

%.bin: %.asc
	icepack $< $@
