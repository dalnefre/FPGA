# Makefile
#
# yosys -p 'synth_ice40 -json fomu_pvt.json' count_3.v count_3_fomu.v
# nextpnr-ice40 --up5k --package uwg30 --pcf ../../Fomu/pcf/fomu-pvt.pcf --json fomu_pvt.json --asc fomu_pvt.asc
# rm fomu_pvt.json
# icepack fomu_pvt.asc fomu_pvt.bit
# rm fomu_pvt.asc
# cp fomu_pvt.bit fomu_pvt.dfu
# dfu-suffix -v 1209 -p 70b1 -a fomu_pvt.dfu
# rm fomu_pvt.bit
# 

PNR_OPTS = --up5k --package uwg30 --pcf ../../Fomu/pcf/fomu-pvt.pcf

SIM =	count_0.sim \
	count_1.sim \
	count_2.sim \
	count_3.sim

VCD =	count_0.vcd \
	count_1.vcd \
	count_2.vcd \
	count_3.vcd

DFU =	count_3_fomu.dfu \
	pwm_0_fomu.dfu

ALL =	$(SIM) $(VCD) $(DFU)

all: $(ALL)

clean:
	rm -f $(ALL) *.json *.asc *.bit *.log

sim: $(SIM)

vcd: $(VCD)

dfu: $(DFU)

count_0.sim: count_0.v
	iverilog -o $@ $^

count_1.sim: count_1.v count_1_tb.v
	iverilog -o $@ $^

count_2.sim: count_2.v count_2_tb.v
	iverilog -o $@ $^

count_3.sim: count_3.v count_3_tb.v
	iverilog -o $@ $^

%.vcd: %.sim
	./$<

count_3_fomu.json: count_3.v count_3_fomu.v
	yosys -p 'synth_ice40 -json $@' $^ >count_3_fomu.log

pwm_0_fomu.json: count_3.v pwm_0.v pwm_0_fomu.v
	yosys -p 'synth_ice40 -json $@' $^ >pwm_0_fomu.log

%.asc: %.json
	nextpnr-ice40 $(PNR_OPTS) --asc $@ --json $<

%.bit: %.asc
	icepack $< $@

%.dfu: %.bit
	cp $< $@
	dfu-suffix -v 1209 -p 70b1 -a $@

