/*

Blink 3 LEDs (one on-board, two external)

*/

`default_nettype none

module top (
  input CLK,    // 16MHz clock for TinyFPGA-BX
  output PIN_8, // --R220--LED--GND
  output PIN_9, // --R220--LED--GND
  output LED,   // User/boot LED next to power LED
  output USBPU  // USB pull-up resistor
);
  reg [25:0] counter;
  always @(posedge CLK) counter <= counter + 1;

  // drive USB pull-up resistor to '0' to disable USB
  assign USBPU = 0;

  assign PIN_8 = counter[25];  // ~3.814 seconds
  assign LED   = counter[24];  // ~1.907 seconds
  assign PIN_9 = counter[23];  // ~0.954 seconds

endmodule
