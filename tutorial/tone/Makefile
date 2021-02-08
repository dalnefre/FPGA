#
# Makefile
#

PNR_OPTS = --up5k --package uwg30 --pcf ../lib/fomu_pvt.pcf

SIM =	square.sim \
	pitch.sim

VCD =	square.vcd \
	pitch.vcd

DFU =	square_fomu.dfu \
	pitch_0_fomu.dfu \
	pitch_1_fomu.dfu

TIME =	square_fomu.time \
	pitch_0_fomu.time \
	pitch_1_fomu.time

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

%.vcd: %.sim
	./$<

square_fomu.json: ../lib/clk_div.v square.v square_fomu.v
	yosys -p 'synth_ice40 -json $@' $^ >square_fomu.log

pitch_0_fomu.json: pitch.v pitch_0_fomu.v
	yosys -p 'synth_ice40 -json $@' $^ >pitch_0_fomu.log

pitch_1_fomu.json: pitch.v player.v pitch_1_fomu.v
	yosys -p 'synth_ice40 -json $@' $^ >pitch_1_fomu.log

%.asc: %.json
	nextpnr-ice40 $(PNR_OPTS) --json $< --asc $@

%.bit: %.asc
	icepack $< $@

%.time: %.asc
	icetime -mit -d up5k -c 48 -r $@ $<

%.dfu: %.bit
	cp $< $@
	dfu-suffix -v 1209 -p 70b1 -a $@

