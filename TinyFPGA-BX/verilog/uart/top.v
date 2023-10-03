/*

Serial UART composed of separate RX and TX modules

*/

`default_nettype none

module top (
  input             CLK,                // 16MHz clock for TinyFPGA-BX
  input             PIN_2,              // RX Data
  output            PIN_1,              // TX Data
  output            LED,                // User/boot LED next to power LED
  output            USBPU               // USB pull-up resistor
);

  parameter CLK_FREQ = 16_000_000;      // clock frequency (Hz)
  parameter BAUD_RATE = 115_200;        // baud rate (bits per second)

  assign USBPU = 1'b0;  // disable USB interface

  wire tx_wr;
  assign tx_wr = 1'b1;  // perpetual write-request

  wire tx_busy;  // busy signal ignored

  reg [7:0] tx_data;
  initial tx_data = "K";  // transmit unending stream of "K" characters

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

  assign PIN_1 = uart_tx;  // transmit on pin #1
  assign LED = uart_tx;  // transmit to LED

endmodule
