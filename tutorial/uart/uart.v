// uart.v
//
// universal asynchronous receiver-transmitter (UART)
//
// requires:
//    serial_rx.v
//    serial_tx.v
//

/*
         +--------------+
         | uart         |
         |              |
    ---->|clk           |
         |              |
      8  |              |
    --/->|tx_data     tx|---->
    ---->|wr            |
    <----|busy          |
         |              |
      8  |              |
    <-/--|rx_data     rx|<----
    ---->|rd            |
    <----|valid         |
    <----|break         |
         |              |
         +--------------+
*/

`include "uart.vh"

module uart #(
  parameter CLK_FREQ = 48_000_000,      // clock frequency (Hz)
  parameter BIT_FREQ = 115_200          // baud rate (bits per second)
) (
  input            clk,                 // system clock

  input      [7:0] tx_data,             // octet to transmit
  input            wr,                  // write data
  output           busy,                // transmitter busy

  output reg [7:0] rx_data,             // octet received
  input            rd,                  // read data (acknowledgement)
  output reg       valid = 1'b0,        // octet is ready
  output           break,               // line break condition

  input            rx,                  // receive line (async)
  output           tx                   // transmit line
);

  // instantiate serial transmitter
  serial_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BIT_FREQ(BIT_FREQ)
  ) SER_TX (
    .clk(clk),
    .data(tx_data),
    .wr(wr),
    .busy(busy),
    .tx(tx)
  );

  // instantiate serial receiver
  serial_rx #(
    .CLK_FREQ(CLK_FREQ),
    .BIT_FREQ(BIT_FREQ)
  ) SER_RX (
    .clk(clk),
    .data(rxd),
    .ready(ready),
    .break(break),
    .rx(rx)
  );

  // RXD buffer
  wire ready;
  wire [7:0] rxd;
  always @(posedge clk)
    begin
      if (ready)
        begin
          rx_data <= rxd;
          valid <= 1'b1;
        end
      if (rd)
        begin
          rx_data <= 0;
          valid <= 1'b0;
        end
    end

endmodule