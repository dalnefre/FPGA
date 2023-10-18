#
# Makefile
#

ALL =	led_freq.vcd \
	alloc.vcd \
	serial_tx.vcd \
	serial_rx.vcd \
	serial_rx+tx.vcd

all: $(ALL)

clean:
	rm -f *.sim *.vcd

%.sim: %_tb.v
	iverilog -o $@ $^

%.vcd: %.sim
	./$<
