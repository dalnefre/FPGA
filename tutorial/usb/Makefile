#
# Makefile
#

SIM =	usb_0.sim \
	usb_1.sim \
	usb_2.sim

VCD =	usb_0.vcd \
	usb_1.vcd \
	usb_2.vcd

ALL =	$(SIM) $(VCD)

all: $(ALL)

clean:
	rm -f $(ALL)

sim: $(SIM)

vcd: $(VCD)

usb_2.sim: usb_0.v usb_1.v usb_2_tb.v
	iverilog -o $@ $^

%.sim: %.v %_tb.v
	iverilog -o $@ $^

%.vcd: %.sim
	./$<
