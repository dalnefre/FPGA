/*

Pulse Counting Component

*/

`default_nettype none

module pulse_cnt #(
  parameter BITS = 1                    // number of counter output bits
) (
  input             i_clk,              // system clock
  input             i_cnt,              // signal to count
  output [BITS-1:0] o_data              // counter output bits
);

  // track previous input
  reg r_cnt;
  initial r_cnt = 1'b0;
  always @(posedge i_clk)
    r_cnt <= i_cnt;

  // count rising edges
  reg [BITS-1:0] counter;
  initial counter = 0;
  always @(posedge i_clk)
    if (!r_cnt && i_cnt)
      counter <= counter + 1'b1;

  assign o_data = counter;

endmodule
