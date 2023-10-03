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
  reg CLK = 0;
  always
    #1 CLK = !CLK;

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
    .i_clk(CLK),
    .i_wr(tx_wr),
    .i_data(tx_data),
    .o_busy(tx_busy),
    .o_tx(uart_tx)
  );

  // feed signals to transmitter
  /*
  reg r_tx_wr;  // introduce register delay...
  initial r_tx_wr = 1'b0;
  always @(posedge CLK)
    r_tx_wr <= !tx_busy;
  assign tx_wr = r_tx_wr;
  */
  assign tx_wr = !tx_busy;
  assign tx_data = "K";

endmodule
