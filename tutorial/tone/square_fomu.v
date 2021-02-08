// square_fomu.v
//
// top-level module for Fomu PVT device
//
// requires:
//    clk_div.v
//    square.v
//

`default_nettype none

`include "fomu_pvt.vh"

module fomu_pvt (
  input  clk_48MHz, // 48MHz oscillator input

  output rgb_0,     // RGB LED pin 0 (**DO NOT** drive directly)
  output rgb_1,     // RGB LED pin 1 (**DO NOT** drive directly)
  output rgb_2,     // RGB LED pin 2 (**DO NOT** drive directly)

  inout  user_1,    // external pin 1
  inout  user_2,    // external pin 2
  inout  user_3,    // external pin 3
  inout  user_4,    // external pin 4

  inout  usb_dp,    // USB D+
  inout  usb_dn,    // USB D-
  output usb_dp_pu  // USB D+ pull-up
);

  // instantiate clock divider
  localparam CLK_FREQ = (`SYS_CLK_FREQ >> 10);  // 46.875 kHz
  wire clk_47kHz;
  clk_div #(
    .N_DIV(10)
  ) DIV_10 (
    .clk_i(clk_48MHz),
    .clk_o(clk_47kHz)
  );

  // connect clock to global buffer
  wire clk;
  SB_GB clk_gb (
    .USER_SIGNAL_TO_GLOBAL_BUFFER(clk_47kHz),
    .GLOBAL_BUFFER_OUTPUT(clk)
  );

  // instantiate tone generator
  localparam TONE_FREQ = 440;  // A4 (aka A440)
  wire spkr;
  tone_gen #(
    .CLK_FREQ(CLK_FREQ),
    .OUT_FREQ(TONE_FREQ)
  ) TONE (
    .clk(clk),
    .out(spkr)
  );

  // configure user pin 1
  wire pin_1_dir = 1;  // 0=input, 1=output
  wire pin_1_in;
  wire pin_1_out;
  SB_IO #(
    .PIN_TYPE(6'b1010_01) // tri-statable output
  ) user_1_io (
    .PACKAGE_PIN(user_1),
    .OUTPUT_ENABLE(pin_1_dir),
    .D_IN_0(pin_1_in),
    .D_OUT_0(pin_1_out)
  );

  // connect user pins
  assign pin_1_out = spkr;  // "speaker" pin
  assign user_2 = 1'b0;  // ground unused pin
  assign user_3 = 1'b0;  // ground unused pin
  assign user_4 = 1'b0;  // ground unused pin

  // connect clock to global buffer
  // instantiate iCE40 LED driver hard logic
  wire led_r, led_g, led_b;
  SB_RGBA_DRV #(
    .CURRENT_MODE(`RGBA_CURRENT_MODE_HALF),
    .RGB0_CURRENT(`RGBA_CURRENT_16mA_08mA),  // green needs more current
    .RGB1_CURRENT(`RGBA_CURRENT_08mA_04mA),
    .RGB2_CURRENT(`RGBA_CURRENT_08mA_04mA)
  ) RGBA_DRIVER (
    .CURREN(1'b1),
    .RGBLEDEN(1'b1),
    .`REDPWM(led_r),    // Red
    .`GREENPWM(led_g),  // Green
    .`BLUEPWM(led_b),   // Blue
    .RGB0(rgb_0),
    .RGB1(rgb_1),
    .RGB2(rgb_2)
  );
  assign led_r = 1'b0;  // unused led off
  assign led_g = 1'b0;  // unused led off
  assign led_b = 1'b0;  // unused led off

  // Drive USB pins to 0 to disconnect Fomu from the host system.
  // Otherwise it would try to talk to us over USB,
  // which wouldn't work since we have no stack.
  assign usb_dp = 1'b0;
  assign usb_dn = 1'b0;
  assign usb_dp_pu = 1'b0;

endmodule