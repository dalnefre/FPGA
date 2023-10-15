/*

Top-Level Verilog Module

Uncomment any pins you want to use in `pins.pcf`

*/

`default_nettype none

`include "fifothru.v"

module top (
  input             clki,               // 48MHz oscillator input on Fomu-PVT
  output            rgb0,               // RGB LED pin 0 (**DO NOT** drive directly)
  output            rgb1,               // RGB LED pin 1 (**DO NOT** drive directly)
  output            rgb2,               // RGB LED pin 2 (**DO NOT** drive directly)
  output            usb_dp,             // USB D+
  output            usb_dn,             // USB D-
  output            usb_dp_pu           // USB D+ pull-up
);
  parameter CLK_FREQ = 48_000_000;      // clock frequency (Hz)

  // disable Fomu USB
  assign usb_dp = 1'b0;
  assign usb_dn = 1'b0;
  assign usb_dp_pu = 1'b0;

  // connect system clock (with buffering)
  wire clk;
  SB_GB clk_gb (
    .USER_SIGNAL_TO_GLOBAL_BUFFER(clki),
    .GLOBAL_BUFFER_OUTPUT(clk)
  );

  // connect RGB LED driver (see: FPGA-TN-1288-ICE40LEDDriverUsageGuide.pdf)
  wire led_r;
  wire led_g;
  wire led_b;
  SB_RGBA_DRV #(
    .CURRENT_MODE("0b1"),               // half current
    .RGB0_CURRENT("0b001111"),          // 8 mA
    .RGB1_CURRENT("0b000011"),          // 4 mA
    .RGB2_CURRENT("0b000011")           // 4 mA
  ) RGBA_DRIVER (
    .CURREN(1'b1),
    .RGBLEDEN(1'b1),
    .RGB0PWM(led_g),                    // green
    .RGB1PWM(led_r),                    // red
    .RGB2PWM(led_b),                    // blue
    .RGB0(rgb0),
    .RGB1(rgb1),
    .RGB2(rgb2)
  );

  // instantiate fifo
  fifothru #(
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

//  assign wr = 1'b1;  // write anytime the fifo has room
  assign wr = phase[0];  // write more slowly
//  assign rd = 1'b1;  // read anytime the fifo has data
  assign rd = phase==2;  // read more slowly

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

  // drive LEDs
  assign led_r = c_out[7];
  assign led_g = c_out[6];
  assign led_b = c_out[5];

endmodule
