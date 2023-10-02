/*

Blink "SOS" in Morse code

*/

`default_nettype none

module top (
  input CLK,    // 16MHz clock for TinyFPGA-BX
  output LED,   // User/boot LED next to power LED
  output USBPU  // USB pull-up resistor
);

  // drive USB pull-up resistor to '0' to disable USB
  assign USBPU = 1'b0;

  // blink pattern
  wire [31:0] pattern = 32'b1010_1000_1110_1110_1110_0010_1010_0000;

  // 26-bit wrap-around counter
  parameter WIDTH = 26;
  reg [WIDTH-1:0] counter;

  // initialize counter to 0
  initial counter = 0;

  // increment counter on every clock
  always @(posedge CLK)
    begin
      counter <= counter + 1'b1;
    end

/*
  // derive index from counter
  wire [WIDTH-1:0] index;
  assign index = counter[WIDTH-1:WIDTH-5];

  // light LED if pattern is set at index
  assign LED = pattern[index];
*/
  // light LED if pattern is set at index derived from counter
  assign LED = pattern[counter[WIDTH-1:WIDTH-5]];

endmodule
