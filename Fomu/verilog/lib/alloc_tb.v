/*

Test Bench for alloc.v

*/

`default_nettype none

`include "alloc.v"

`timescale 10ns/1ns

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("alloc.vcd");
      $dumpvars(0, test_bench);
      #1600;
      $finish;
    end

  // generate chip clock (50MHz simulation time)
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate allocator
  wire [15:0] alloc_addr;
  wire alloc_rdy;
  wire free_done;
  alloc #(
    .ADDR_SZ(4)
  ) ALLOC (
    .i_clk(clk),
    .i_wr(1'b0),
    .i_data(UNDEF),
    .i_alloc(alloc_stb),
    .o_addr(alloc_addr),
    .o_ready(alloc_rdy),
    .i_rd(1'b0),
    .i_free(free_stb),
    .i_addr(free_addr),
    .o_done(free_done)
  );

/*
  // request allocation every 13 clocks
  reg alloc_stb;  // allocation request
  initial alloc_stb = 1'b0;
  reg [3:0] alloc_cnt;
  initial alloc_cnt = 13;
  always @(posedge clk)
    if (alloc_cnt == 0)
      begin
        alloc_cnt <= 13;  // reset counter
        alloc_stb <= 1'b1;  // request strobe
      end
    else
      begin
        alloc_cnt <= alloc_cnt - 1'b1;  // decrement counter
        alloc_stb <= 1'b0;  // clear request
      end
*/

  // FIXME: move definitions to an include file?
  localparam UNDEF  = 16'h0000;         // undefined value

  // script control signals
  reg alloc_stb;  // allocation request
//  initial alloc_stb = 1'b0;
  reg free_stb;  // free request
//  initial free_stb = 1'b0;
  reg [15:0] free_addr;
  initial
    begin
      alloc_stb = 1'b0;
      free_stb = 1'b0;
      free_addr = UNDEF;
      #1.2  // align for @(posedge clk)
      #2  // wait 1 clock-cycle
      alloc_stb = 1'b1;
      #2
      alloc_stb = 1'b0;
      #4
      alloc_stb = 1'b1;
      #6
      alloc_stb = 1'b0;
      #2
      free_stb = 1'b1;
      free_addr = 16'h5001;
      #2
      free_addr = 16'h5003;
      #2
      free_stb = 1'b0;
      free_addr = UNDEF;
      alloc_stb = 1'b1;
      #2
      free_stb = 1'b1;
      free_addr = 16'h5002;
      #2
      alloc_stb = 1'b0;
      free_stb = 1'b0;
      free_addr = UNDEF;
    end

endmodule
