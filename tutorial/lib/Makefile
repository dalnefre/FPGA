#
# Makefile
#

PNR_OPTS = --up5k --package uwg30 --pcf fomu_pvt.pcf

SIM =	user.sim \
	freq.sim \
	debounce.sim \
	buffer.sim

VCD =	user.vcd \
	freq.vcd \
	debounce.vcd \
	buffer.vcd

DFU =	user_fomu.dfu \
	freq_fomu.dfu

TIME =	user_fomu.time \
	freq_fomu.time

ALL =	$(SIM) $(VCD) $(DFU)

all: $(ALL)

clean:
	rm -f $(ALL) $(TIME) *.json *.asc *.bit *.log

sim: $(SIM)

vcd: $(VCD)

dfu: $(DFU)

time: $(TIME)

%.sim: %.v %_tb.v
	iverilog -o $@ $^

#user.sim: prescale.v user.v user_tb.v
user.sim: clk_div.v user.v user_tb.v
	iverilog -o $@ $^

debounce.sim: async.v hyster.v debounce.v debounce_tb.v
	iverilog -o $@ $^

buffer.sim: source.v buffer.v buffer_tb.v
	iverilog -o $@ $^

%.vcd: %.sim
	./$<

#user_fomu.json: prescale.v user.v fomu_pvt.v
user_fomu.json: clk_div.v user.v fomu_pvt.v
	yosys -p 'synth_ice40 -json $@' $^ >user_fomu.log

freq_fomu.json: clk_div.v freq.v freq_top.v fomu_47khz.v
	yosys -p 'synth_ice40 -json $@' $^ >freq_fomu.log

%.asc: %.json
	nextpnr-ice40 $(PNR_OPTS) --json $< --asc $@

%.bit: %.asc
	icepack $< $@

%.time: %.asc
	icetime -mit -d up5k -c 48 -r $@ $<

%.dfu: %.bit
	cp $< $@
	dfu-suffix -v 1209 -p 70b1 -a $@

