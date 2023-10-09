/*

Test Bench for xform.v

*/

`default_nettype none

`include "xform.v"

`timescale 10ns/1ns

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("xform.vcd");
      $dumpvars(0, test_bench);
      #1200;
      $finish;
    end

  // generate chip clock (50MHz simulation time)
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate xform
  xform XCASE (
    .i_clk(clk),
    .i_wr(wr),
    .i_data(c_in),
    .o_bsy(bsy),
    .i_rd(rd),
    .o_data(out),
    .o_rdy(rdy)
  );

  // xform signals
  wire wr;
  wire bsy;
  wire rd;
  wire [7:0] out;
  wire rdy;

  assign wr = !bsy;  // write everytime the component has room
//  assign wr = (!bsy & phase[0]);  // write more slowly
  assign rd = rdy;  // read everytime the component has data
//  assign rd = (rdy & phase==2);  // read more slowly

  // 4-phase counter to pace read/write
  reg [1:0] phase;
  initial phase = 0;
  always @(posedge clk)
    phase <= phase + 1'b1;

  // input writer
  reg [7:0] c_in;
  initial c_in = " ";  // = 8'h20;
  always @(posedge clk)
    if (wr)
      c_in <= c_in + 1'b1;

  // output reader
  reg [7:0] c_out;
  initial c_out = -1;
  always @(posedge clk)
    if (rd)
      c_out <= out;

endmodule
