/*

Integrated Serial UART Subsystem

    +----------+
    | uart     |
    |          |
    |      i_rx|<---
    |          |
    |      o_tx|--->
    |          |
 +->|i_clk     |
 |  +----------+

*/

`default_nettype none

`include "../lib/serial_rx.v"
`include "../lib/serial_tx.v"
`include "xform.v"

module uart #(
  parameter CLK_FREQ = 48_000_000,      // clock frequency (Hz)
  parameter BAUD_RATE = 115_200         // baud rate (bits per second)
) (
  input             i_clk,              // system clock
  input             i_rx,               // serial receive line
  output            o_tx                // serial transmit line
);

  // instantiate serial transmitter
  wire tx_wr;
  wire [7:0] tx_data;
  wire tx_busy;
  wire uart_tx;
  serial_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
  ) SER_TX (
    .i_clk(i_clk),
    .i_wr(tx_wr),
    .i_data(tx_data),
    .o_busy(tx_busy),
    .o_tx(uart_tx)
  );

  // connect serial_tx
  //assign tx_wr = 1'b1;  // perpetual write-request
  //assign tx_data = "K";  // transmit unending stream of "K" characters
  assign o_tx = uart_tx;

  // instantiate serial receiver
  wire uart_rx;
  wire rx_wr;
  wire [7:0] rx_data;
  serial_rx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
  ) SER_RX (
    .i_clk(i_clk),
    .i_rx(uart_rx),
    .o_wr(rx_wr),
    .o_data(rx_data)
  );

  // connect serial_rx
  assign uart_rx = i_rx;
  //assign tx_wr = rx_wr;  // write-request from receiver
  //assign tx_data = rx_data;  // character data from receiver

  // instantiate transform
  wire x_bsy;
  wire x_rdy;
  xform XFORM (
    .i_clk(i_clk),
    .i_wr(rx_wr),
    .i_data(rx_data),
    .o_bsy(x_bsy),
    .i_rd(tx_wr),
    .o_data(tx_data),
    .o_rdy(x_rdy)
  );
  /*
  assign tx_wr = x_rdy;
  */
  // FIXME: this bypass-register should be equivalent to x_rdy!
  reg r_rx_wr;
  initial r_rx_wr = 1'b0;
  always @(posedge i_clk)
    r_rx_wr <= rx_wr;
  assign tx_wr = r_rx_wr;

endmodule
