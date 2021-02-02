// serial_rx0_tb.v
//
// simulation test bench for serial_rx0.v
//

`default_nettype none

`include "uart.vh"

/*
The following waveform represents transmission of the letter 'K' in isolation.
_____     _______     ___         ___     _________
     \___/       \___/   \_______/   \___/          
IDLE | + | 1 | 1 | 0 | 1 | 0 | 0 | 1 | 0 | - | IDLE
     START                                STOP
*/

module test_bench;

  localparam CLK_FREQ = 48;
  localparam BIT_FREQ = 5;
  localparam BIT_PERIOD = CLK_FREQ / BIT_FREQ;
  localparam FULL_BIT_TIME = BIT_PERIOD - 1;
  localparam PACE = BIT_PERIOD << 1;  // 2 edges per clock-cycle

  // dump simulation signals
  initial
    begin
      $dumpfile("serial_rx0.vcd");
      $dumpvars(0, test_bench);
      $display("PACE = %d", PACE);
      RX = `IDLE_BIT;
      #(PACE);
      RX = `START_BIT;
      #(PACE);
      RX = 1'b1;  // bit 0
      #(PACE);
      RX = 1'b1;  // bit 1
      #(PACE);
      RX = 1'b0;  // bit 2
      #(PACE);
      RX = 1'b1;  // bit 3
      #(PACE);
      RX = 1'b0;  // bit 4
      #(PACE);
      RX = 1'b0;  // bit 5
      #(PACE);
      RX = 1'b1;  // bit 6
      #(PACE);
      RX = 1'b0;  // bit 7
      #(PACE);
      RX = `STOP_BIT;
      #(PACE);
      RX = `START_BIT; //`IDLE_BIT;
      #(PACE);
      $finish;
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate serial receiver
  reg RX;
  serial_rx #(
    .CLK_FREQ(CLK_FREQ),
    .BIT_FREQ(BIT_FREQ)
  ) SER_RX (
    .clk(clk),
    .rx(RX)
  );

endmodule
