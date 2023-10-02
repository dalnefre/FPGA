#
# Makefile
#

TOP	= template
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
