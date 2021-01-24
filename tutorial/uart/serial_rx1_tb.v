// serial_rx1_tb.v
//
// simulation test bench for serial_rx1.v
//

`include "uart.vh"

`define CLK_FREQ 100
`define BIT_FREQ 7
`define PACE ((`CLK_FREQ * 2 / `BIT_FREQ) - 1)

/*
The following waveform represents transmission of a single letter 'K' in isolation.
_____     _______     ___         ___     _________
     \___/       \___/   \_______/   \___/          
IDLE | + | 1 | 1 | 0 | 1 | 0 | 0 | 1 | 0 | - | IDLE
     START                                STOP
*/

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("serial_rx1.vcd");
      $dumpvars(0, test_bench);
      $display("`PACE = %d", `PACE);
      RX = `IDLE_BIT;
      #(`PACE);
      RX = `START_BIT;
      #(`PACE);
      RX = 1'b1;  // bit 0
      #(`PACE);
      RX = 1'b1;  // bit 1
      #(`PACE);
      RX = 1'b0;  // bit 2
      #(`PACE);
      RX = 1'b1;  // bit 3
      #(`PACE);
      RX = 1'b0;  // bit 4
      #(`PACE);
      RX = 1'b0;  // bit 5
      #(`PACE);
      RX = 1'b1;  // bit 6
      #(`PACE);
      RX = 1'b0;  // bit 7
      #(`PACE);
      RX = `STOP_BIT;
      #(`PACE);
      RX = `START_BIT; //`IDLE_BIT;
      #(`PACE);
      $finish;
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate serial receiver
  reg RX;
  serial_rx #(
    .CLK_FREQ(`CLK_FREQ),
    .BIT_FREQ(`BIT_FREQ)
  ) SER_RX (
    .clk(clk),
    .rx(RX)
  );

endmodule