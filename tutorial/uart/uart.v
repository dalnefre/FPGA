// uart.v
//
// universal asynchronous receiver-transmitter (UART)
//

`include "uart.vh"

module uart #(
  parameter CLK_FREQ = 48_000_000,      // clock frequency (Hz)
  parameter BIT_FREQ = 115_200          // baud rate (bits per second)
) (
  input            clk,                 // system clock

  input            wr,                  // write data
  input      [7:0] din,                 // octet to transmit
  output           busy,                // transmitter busy
  output           tx,                  // transmit data

  input            rx,                  // received data (async)
  output           break,               // line break condition
  output           ready,               // octet is ready
  output     [7:0] dout                 // octet received
);

  // instantiate serial transmitter
  serial_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BIT_FREQ(BIT_FREQ)
  ) SER_TX (
    .clk(clk),
    .wr(wr),
    .data(din),
    .busy(busy),
    .tx(tx)
  );

  // instantiate serial receiver
  serial_rx #(
    .CLK_FREQ(CLK_FREQ),
    .BIT_FREQ(BIT_FREQ)
  ) SER_RX (
    .clk(clk),
    .rx(rx),
    .break(break),
    .ready(ready),
    .data(dout)
  );

endmodule