// fomu_48Mhz.v
//
// top-level module for Fomu PVT device (48 Mhz clock)
//
// requires:
//    top.v
//

`default_nettype none

`include "fomu_pvt.vh"

module fomu_pvt (
  input             clk_48MHz,          // 48 MHz oscillator input

  output            rgb_0,              // RGB LED pin 0
  output            rgb_1,              // RGB LED pin 1
  output            rgb_2,              // RGB LED pin 2

  inout             user_1,             // user i/o pin 1
  inout             user_2,             // user i/o pin 2
  inout             user_3,             // user i/o pin 3
  inout             user_4,             // user i/o pin 4

  inout             usb_dp,             // USB D+
  inout             usb_dn,             // USB D-
  output            usb_dp_pu           // USB D+ pull-up
);

  // connect clock to global buffer
  localparam CLK_FREQ = `SYS_CLK_FREQ;  // 48 MHz
  wire clk;
/*
  SB_GB clk_gb (
    .USER_SIGNAL_TO_GLOBAL_BUFFER(clk_48MHz),
    .GLOBAL_BUFFER_OUTPUT(clk)
  );
*/
  assign clk = clk_48MHz;

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

  // instantiate user design
  top #(
    .CLK_FREQ(CLK_FREQ)
  ) USER (
    .clk(clk),
    .led_r(led_r),
    .led_g(led_g),
    .led_b(led_b)
  );

/*
  // Configure user pin 1
  wire pin_1_dir = 0;  // 0=input, 1=output
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
*/

  // Drive USB pins to 0 to disconnect Fomu from the host system.
  // Otherwise it would try to talk to us over USB,
  // which wouldn't work since we have no stack.
  assign usb_dp = 1'b0;
  assign usb_dn = 1'b0;
  assign usb_dp_pu = 1'b0;

endmodule
