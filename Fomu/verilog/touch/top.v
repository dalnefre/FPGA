/*

Fomu "touch-pad" Button Demo

*/

`default_nettype none

`include "../lib/clk_sync.v"
`include "../lib/led_freq.v"

module top (
  input             clki,               // 48MHz oscillator input on Fomu-PVT
  output            rgb0,               // RGB LED pin 0 (**DO NOT** drive directly)
  output            rgb1,               // RGB LED pin 1 (**DO NOT** drive directly)
  output            rgb2,               // RGB LED pin 2 (**DO NOT** drive directly)
  output            user_1,             // User I/O Pad #1 (nearest to notch)
  output            user_2,             // User I/O Pad #2
  output            user_3,             // User I/O Pad #3
  output            user_4,             // User I/O Pad #4
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

  // designate user i/o pins
//  assign user_1 = 1'b0;                 // LEFT
  assign user_2 = 1'b0;                 // GND
  assign user_3 = 1'b0;                 // GND
//  assign user_4 = 1'b1;                 // RIGHT

  localparam SB_IO_TYPE_SIMPLE_INPUT = 6'b000001;
  wire i_left;                          // LEFT (active low)
  SB_IO #(
    .PIN_TYPE(SB_IO_TYPE_SIMPLE_INPUT),
    .PULLUP(1'b1)
  ) user_1_io (
    .PACKAGE_PIN(user_1),
    .OUTPUT_ENABLE(1'b0),  // FIXME: not needed?
    .INPUT_CLK(clk),
    .D_IN_0(i_left),
  );

  localparam SB_IO_TYPE_SIMPLE_INPUT = 6'b000001;
  wire i_right;                         // RIGHT (active low)
  SB_IO #(
    .PIN_TYPE(SB_IO_TYPE_SIMPLE_INPUT),
    .PULLUP(1'b1)
  ) user_4_io (
    .PACKAGE_PIN(user_4),
    .OUTPUT_ENABLE(1'b0),  // FIXME: not needed?
    .INPUT_CLK(clk),
    .D_IN_0(i_right),
  );

  // abstract "buttons" (synchronized)
  wire btn_1;
  clk_sync SYNC_1 (
    .i_clk(clk),
    .i_ext(!i_left && i_right),
    .o_reg(btn_1)
  );

  wire btn_2;
  clk_sync SYNC_2 (
    .i_clk(clk),
    .i_ext(i_left && !i_right),
    .o_reg(btn_2)
  );

  wire btn_3;
  clk_sync SYNC_3 (
    .i_clk(clk),
    .i_ext(!i_left && !i_right),
    .o_reg(btn_3)
  );

/*
  // connect buttons to LEDs
  assign led_r = btn_1;
  assign led_g = btn_2;
  assign led_b = btn_3;
*/
  // instantiate LED frequency limiters
  led_freq FREQ_R (
    .i_clk(clk),
    .i_led(btn_1),
    .o_led(led_r)
  );
  led_freq FREQ_G (
    .i_clk(clk),
    .i_led(btn_2),
    .o_led(led_g)
  );
  led_freq FREQ_B (
    .i_clk(clk),
    .i_led(btn_3),
    .o_led(led_b)
  );

endmodule
