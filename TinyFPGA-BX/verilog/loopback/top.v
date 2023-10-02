/*

Loopback wire connecting input to output w/ LED monitor

Echo data from RX back to TX immediately, without modification.
Whenever RX is high, start a counter to light the LED for 10us.

*/

`default_nettype none

module top (
  input CLK,    // 16MHz clock for TinyFPGA-BX
  input PIN_2,  // RX Data
  output PIN_1, // TX Data
  output LED,   // User/boot LED next to power LED
  output USBPU  // USB pull-up resistor
);

  assign USBPU = 1'b0;  // disable USB interface

  wire i_data;
  assign i_data = PIN_2;

  wire o_data;
  assign PIN_1 = o_data;

  assign o_data = i_data;  // transfer input to output

  reg [7:0] counter;
  initial counter = 0;

  wire active;
  assign active = |counter;

  always @(posedge CLK)
    if (i_data)
      counter <= 8'd160;  // 10us @ 16MHz
    else if (active)
      counter <= counter - 1'b1;

  assign LED = active;  // stretch input strobe to light LED

endmodule
