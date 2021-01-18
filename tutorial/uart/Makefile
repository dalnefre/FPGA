#
# Makefile
#

SIM =	baud_gen.sim \
	serial_tx0.sim \
	sync.sim \
	serial_rx.sim \
	serial_tx.sim \
	uart.sim

VCD =	baud_gen.vcd \
	serial_tx0.vcd \
	sync.vcd \
	serial_rx.vcd \
	serial_tx.vcd \
	uart.vcd

ALL =	$(SIM) $(VCD)

all: $(ALL)

clean:
	rm -f $(ALL)

sim: $(SIM)

vcd: $(VCD)

serial_tx0.sim: baud_gen.v serial_tx0.v serial_tx0_tb.v
	iverilog -o $@ $^

sync.sim: sync_tb.v
	iverilog -o $@ $^

uart.sim: serial_rx.v serial_tx.v uart.v uart_tb.v
	iverilog -o $@ $^

%.sim: %.v %_tb.v
	iverilog -o $@ $^

%.vcd: %.sim
	./$<

