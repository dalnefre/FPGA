/*

Test Bench for pulse_cnt.v

*/

`timescale 100ns/1ns

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("pulse_cnt.vcd");
      $dumpvars(0, test_bench);
      #1200;
      $finish;
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate timer component
  wire base;
  timer #(
    .WIDTH(2)
  ) TIMER (
    .i_clk(clk),
    .o_data(base)
  );

  // instantiate 1st pulse counting component
  wire [1:0] cnt1;
  pulse_cnt #(
    .BITS(2)
  ) COUNT1 (
    .i_clk(clk),
    .i_cnt(base),
    .o_data(cnt1)
  );

  // instantiate 2nd pulse counting component
  wire [2:0] cnt2;
  pulse_cnt #(
    .BITS(3)
  ) COUNT2 (
    .i_clk(clk),
    .i_cnt(cnt1[1]),
    .o_data(cnt2)
  );

  // drive LEDs from timer bits
  wire led_r;
  wire led_g;
  wire led_b;
  assign led_r = cnt2[2];
  assign led_g = cnt2[1];
  assign led_b = cnt2[0];

endmodule
