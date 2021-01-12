#
# Makefile
#

SIM =	pitch.sim

VCD =	pitch.vcd

ALL =	$(SIM) $(VCD)

all: $(ALL)

clean:
	rm -f $(ALL)

sim: $(SIM)

vcd: $(VCD)

%.sim: %.v %_tb.v
	iverilog -o $@ $^

%.vcd: %.sim
	./$<
