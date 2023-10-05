/*

Test Bench for fifo.v

*/

`timescale 100ns/1ns

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("fifo.vcd");
      $dumpvars(0, test_bench);
      #1200;
      $finish;
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate fifo
  fifo #(
    .N_ADDR(3)
  ) FIFO (
    .i_clk(clk),
    .i_wr(wr),
    .i_data(c_in),
    .o_full(full),
    .i_rd(rd),
    .o_data(out),
    .o_empty(empty)
  );

  // fifo signals
  wire wr;
  wire full;
  wire rd;
  wire [7:0] out;
  wire empty;

//  assign wr = !full;  // write everytime the fifo has room
  assign wr = (!full & phase[0]);  // write more slowly
//  assign rd = !empty;  // read everytime the fifo has data
  assign rd = (!empty & phase==2);  // read more slowly

  // 4-phase counter to pace read/write
  reg [1:0] phase;
  initial phase = 0;
  always @(posedge clk)
    phase <= phase + 1'b1;

  // input writer
  reg [7:0] c_in;
  initial c_in = 8'h80;
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
