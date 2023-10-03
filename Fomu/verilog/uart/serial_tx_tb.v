/*

Serial Transmitter Test Bench

*/

`timescale 100ns/1ns

module test_bench;

  //localparam CLK_FREQ = 16_000_000;     // clock frequency (Hz)
  //localparam BAUD_RATE = 115_200;       // baud rate (bits per second)
  localparam CLK_FREQ = 16_000;         // clock frequency (Hz)
  localparam BAUD_RATE = 1_200;         // baud rate (bits per second)

  // dump simulation signals
  initial
    begin
      $dumpfile("serial_tx.vcd");
      $dumpvars(0, test_bench);
      #1600;
      $finish;
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // uart signals
  wire tx_wr;
  wire [7:0] tx_data;
  wire tx_busy;  // busy signal ignored
  wire uart_tx;

  // instantiate serial transmitter
  serial_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
  ) SER_TX (
    .i_clk(clk),
    .i_wr(tx_wr),
    .i_data(tx_data),
    .o_busy(tx_busy),
    .o_tx(uart_tx)
  );

  assign tx_wr = 1'b1;  // perpetual write-request
  assign tx_data = "K";

endmodule
