/*

RGB LED blinker (fast counter)

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

  // declare specific counter bits
  wire bit_28;
  wire bit_27;
  wire bit_26;
  wire bit_25;
  wire bit_24;

//
// 2-stage design
//

  // stage-zero counter (driven directly by system clock)
  reg [14:0] cnt_0;  // count bits [14:0]
  initial cnt_0 = 0;
  always @(posedge clk)
    cnt_0 <= cnt_0 + 1'b1;
  wire max_0;
  assign max_0 = &cnt_0;  // cnt_0 at maximum

  // stage-one counter
  reg [13:0] cnt_1;  // count bits [28:15]
  initial cnt_1 = 0;
  always @(posedge clk)
    if (max_0)
      cnt_1 <= cnt_1 + 1'b1;

  // assign counter bits
  assign bit_28 = cnt_1[13];             // ~11.2s cycle,  ~5.6s on/off
  assign bit_27 = cnt_1[12];             //  ~5.6s cycle,  ~2.8s on/off
  assign bit_26 = cnt_1[11];             //  ~2.8s cycle,  ~1.4s on/off
  assign bit_25 = cnt_1[10];             //  ~1.4s cycle,  ~0.7s on/off
  assign bit_24 = cnt_1[9];              //  ~0.7s cycle,  ~0.35s on/off

/*
//
// 4-stage design
//

  // stage-zero counter (driven directly by system clock)
  reg [7:0] cnt_0;  // count bits [7:0]
  initial cnt_0 = 0;
  always @(posedge clk)
    cnt_0 <= cnt_0 + 1'b1;
  wire max_0;
  assign max_0 = &cnt_0;  // cnt_0 at maximum

  // stage-one counter
  reg [7:0] cnt_1;  // count bits [15:8]
  initial cnt_1 = 0;
  always @(posedge clk)
    if (max_0)
      cnt_1 <= cnt_1 + 1'b1;
  wire max_1;
  assign max_1 = &cnt_1;  // cnt_1 at maximum

  // stage-two counter
  reg [7:0] cnt_2;  // count bits [23:16]
  initial cnt_2 = 0;
  always @(posedge clk)
    if (max_0 && max_1)
      cnt_2 <= cnt_2 + 1'b1;
  wire max_2;
  assign max_2 = &cnt_2;  // cnt_2 at maximum

  // stage-three counter
  reg [4:0] cnt_3;  // count bits [28:24]
  initial cnt_3 = 0;
  always @(posedge clk)
    if (max_0 && max_1 && max_2)
      cnt_3 <= cnt_3 + 1'b1;

  // assign counter bits
  assign bit_28 = cnt_3[4];             // ~11.2s cycle,  ~5.6s on/off
  assign bit_27 = cnt_3[3];             //  ~5.6s cycle,  ~2.8s on/off
  assign bit_26 = cnt_3[2];             //  ~2.8s cycle,  ~1.4s on/off
  assign bit_25 = cnt_3[1];             //  ~1.4s cycle,  ~0.7s on/off
  assign bit_24 = cnt_3[0];             //  ~0.7s cycle,  ~0.35s on/off
*/

  // drive LEDs from slower-changing counter bits
  assign led_r = bit_28;
  assign led_g = bit_27;
  assign led_b = bit_26;
//  assign led_x = bit_25;
//  assign led_x = bit_24;

endmodule
