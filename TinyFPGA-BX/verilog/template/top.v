/*

Top-Level Verilog Module -- Basic LED blinker

Uncomment any pins you want to use in `pins.pcf`

*/

`default_nettype none

module top (
  input CLK,    // 16MHz clock for TinyFPGA-BX
  output LED,   // User/boot LED next to power LED
  output USBPU  // USB pull-up resistor
);

  // drive USB pull-up resistor to '0' to disable USB
  assign USBPU = 1'b0;

  reg [23:0] counter;
  always @(posedge CLK) counter <= counter + 1'b1;

  assign LED = counter[23];  // ~0.954 seconds

endmodule
