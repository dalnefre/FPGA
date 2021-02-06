#
# Makefile
#

SIM =	lockstep.sim

VCD =	lockstep.vcd

ALL =	$(SIM) $(VCD)

all: $(ALL)

clean:
	rm -f $(ALL)

sim: $(SIM)

vcd: $(VCD)

%.sim: %.v %_tb.v
	iverilog -o $@ $^

lockstep.sim: ls_source.v lockstep.v lockstep_tb.v
	iverilog -o $@ $^

%.vcd: %.sim
	./$<
