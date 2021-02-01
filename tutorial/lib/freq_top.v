// freq_top.v
//
// frequency generator top-level design
//

`default_nettype none

module top #(
  parameter         CLK_FREQ = 183      // clock frequency
) (
  input             clk,                // input clock
  output            led_r,              // red LED signal
  output            led_g,              // green LED signal
  output            led_b               // blue LED signal
);

  // instantiate device-under-test
  wire led;
  freq #(
    .N_CNT(4)
  ) DUT (
    .clk(clk),
    .lo(4'h7),
    .hi(4'hF),
    .out(led)
  );

  assign led_r = 1'b1;
  assign led_g = led;
  assign led_b = 1'b0;

endmodule
