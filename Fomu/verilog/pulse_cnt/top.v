/*

Top-Level Verilog Module -- LED blinker using pulse_cnt to break up timer logic

*/

`default_nettype none

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

  // instantiate timer component
  wire base;
  timer #(
    .CLK_FREQ(CLK_FREQ),
    .WIDTH(10)
  ) TIMER (
    .i_clk(clk),
    .o_data(base)
  );

  // instantiate 1st pulse counting component
  wire [9:0] cnt1;
  pulse_cnt #(
    .BITS(10)
  ) COUNT1 (
    .i_clk(clk),
    .i_cnt(base),
    .o_data(cnt1)
  );

  // instantiate 2nd pulse counting component
  wire [9:0] cnt2;
  pulse_cnt #(
    .BITS(10)
  ) COUNT2 (
    .i_clk(clk),
    .i_cnt(cnt1[9]),
    .o_data(cnt2)
  );

  // drive LEDs from timer bits
  assign led_r = cnt2[9];
  assign led_g = cnt2[8];
  assign led_b = cnt2[7];

endmodule
