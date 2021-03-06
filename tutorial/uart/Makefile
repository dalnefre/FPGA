#
# Makefile
#

PNR_OPTS = --up5k --package uwg30 --pcf ../../Fomu/pcf/fomu-pvt.pcf

SIM =	baud_gen.sim \
	serial_tx0.sim \
	sync.sim \
	serial_rx.sim \
	serial_tx.sim \
	serial_rx1.sim \
	serial_rx0.sim \
	uart.sim \
	uart1.sim

VCD =	baud_gen.vcd \
	serial_tx0.vcd \
	sync.vcd \
	serial_rx.vcd \
	serial_tx.vcd \
	serial_rx1.vcd \
	serial_rx0.vcd \
	uart.vcd \
	uart1.vcd

DFU =	uart_0_fomu.dfu \
	uart_1_fomu.dfu

TIME =	uart_0_fomu.time \
	uart_1_fomu.time

ALL =	$(SIM) $(VCD) $(DFU)

all: $(ALL)

clean:
	rm -f $(ALL) $(TIME) *.json *.asc *.bit *.log

sim: $(SIM)

vcd: $(VCD)

dfu: $(DFU)

time: $(TIME)

serial_tx0.sim: baud_gen.v serial_tx0.v serial_tx0_tb.v
	iverilog -o $@ $^

sync.sim: sync_tb.v
	iverilog -o $@ $^

uart.sim: serial_rx.v serial_tx.v uart.v uart_tb.v
	iverilog -o $@ $^

uart1.sim: serial_rx1.v serial_tx.v uart.v uart1_tb.v
	iverilog -o $@ $^

%.sim: %.v %_tb.v
	iverilog -o $@ $^

%.vcd: %.sim
	./$<

#uart_0_fomu.json: serial_rx.v serial_tx.v uart.v uart_0_fomu.v
uart_0_fomu.json: serial_rx0.v serial_tx.v uart.v uart_0_fomu.v
	yosys -p 'synth_ice40 -json $@' $^ >uart_0_fomu.log

uart_1_fomu.json: ../lib/hyster.v serial_rx1.v serial_tx.v uart.v uart_1_fomu.v
	yosys -p 'synth_ice40 -json $@' $^ >uart_1_fomu.log

%.asc: %.json
	nextpnr-ice40 $(PNR_OPTS) --json $< --asc $@

%.bit: %.asc
	icepack $< $@

%.time: %.asc
	icetime -mit -d up5k -c 48 -r $@ $<

%.dfu: %.bit
	cp $< $@
	dfu-suffix -v 1209 -p 70b1 -a $@

