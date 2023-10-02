#
# Makefile
#

PNR_OPTS = --up5k --package uwg30 --pcf ../../Fomu/pcf/fomu-pvt.pcf

SIM =	count_0.sim \
	count_1.sim \
	count_2.sim \
	count_3.sim \
	pwm_1.sim \
	pwm_0.sim

VCD =	count_0.vcd \
	count_1.vcd \
	count_2.vcd \
	count_3.vcd \
	pwm_1.vcd \
	pwm_0.vcd

DFU =	count_3_fomu.dfu \
	pwm_0_fomu.dfu \
	pwm_1_fomu.dfu

ALL =	$(SIM) $(VCD) $(DFU)

all: $(ALL)

clean:
	rm -f $(ALL) *.json *.asc *.bit *.log

sim: $(SIM)

vcd: $(VCD)

dfu: $(DFU)

count_0.sim: count_0.v
	iverilog -o $@ $^

pwm_0.sim: count_3.v pwm_0.v pwm_0_tb.v
	iverilog -o $@ $^

pwm_1.sim: count_3.v pwm_0.v pwm_1_tb.v
	iverilog -o $@ $^

%.sim: %.v %_tb.v
	iverilog -o $@ $^

%.vcd: %.sim
	./$<

count_3_fomu.json: count_3_fomu.v
	yosys -p 'synth_ice40 -json $@' $^ >count_3_fomu.log

pwm_0_fomu.json: count_3.v pwm_0.v pwm_0_fomu.v
	yosys -p 'synth_ice40 -json $@' $^ >pwm_0_fomu.log

pwm_1_fomu.json: count_3.v pwm_0.v pwm_1_fomu.v
	yosys -p 'synth_ice40 -json $@' $^ >pwm_1_fomu.log

%.asc: %.json
	nextpnr-ice40 $(PNR_OPTS) --json $< --asc $@

%.bit: %.asc
	icepack $< $@

%.dfu: %.bit
	cp $< $@
	dfu-suffix -v 1209 -p 70b1 -a $@

# Upload design:
#   $ dfu-util -D count_3_fomu.dfu
