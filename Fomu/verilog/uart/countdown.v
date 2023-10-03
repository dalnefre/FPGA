/*

Countdown Timer Component

*/

`default_nettype none

module countdown #(
  parameter INIT = 0,                   // starting count
  parameter BITS = 4                    // number of count bits = $clog2(INIT)
) (
  input             i_clk,              // system clock
  input             i_wr,               // write request
  input  [BITS-1:0] i_data,             // write data
  input             i_en,               // count enable
  output [BITS-1:0] o_data              // read count
);

  reg [BITS-1:0] counter;
  initial counter = INIT;
  always @(posedge i_clk)
    if (i_wr)
      counter <= i_data;
    else if (i_en)
      counter <= counter - 1'b1;

  assign o_data = counter;

endmodule
