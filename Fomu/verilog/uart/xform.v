/*

Transform Swaps Uppercase/Lowercase

    +---------------+
    | xform         |
    |               |
=N=>|i_data     i_rd|<---
--->|i_wr     o_data|=N=>
<---|o_bsy     o_rdy|--->
    |               |
 +->|i_clk          |
 |  +---------------+

*/

`default_nettype none

module xform #(
  parameter N = 8                       // data bus bit width
) (
  input             i_clk,              // system clock
  input             i_wr,               // write request
  input     [N-1:0] i_data,             // write data
  output reg        o_bsy,              // device busy condition
  input             i_rd,               // read request
  output reg[N-1:0] o_data,             // read data
  output reg        o_rdy               // result ready condition
);
  initial o_bsy = 1'b0;
  initial o_data = -1;//0;
  initial o_rdy = 1'b0;

  wire wr;                              // valid write request
  wire rd;                              // valid read request
  assign wr = i_wr && !o_bsy;
  assign rd = i_rd && o_rdy;

  always @(posedge i_clk)
    if (wr)
      begin
        o_bsy <= 1'b1;
/*
        o_data <= i_data;  // pass-thru
*/
        o_data <= (i_data >= "A" && i_data <= "Z") || (i_data >= "a" && i_data <= "z")
          ? i_data ^ 8'h20
          : i_data;
        o_rdy <= 1'b1;
      end

  always @(posedge i_clk)
    if (rd)
      begin
        o_bsy <= 1'b0;
        o_rdy <= 1'b0;
      end

endmodule
