// fomu_pvt.v
//
// top-level module for Fomu PVT device
//
// requires:
//    top.v
//

`include "fomu_pvt.vh"

module fomu_pvt (
  input             clk_48MHz,          // 48MHz oscillator input

  output            rgb_0,              // RGB LED pin 0
  output            rgb_1,              // RGB LED pin 1
  output            rgb_2,              // RGB LED pin 2

  inout             touch_1,            // touchpad pin 1
  inout             touch_2,            // touchpad pin 2
  inout             touch_3,            // touchpad pin 3
  inout             touch_4,            // touchpad pin 4

  inout             usb_dp,             // USB D+
  inout             usb_dn,             // USB D-
  output            usb_dp_pu           // USB D+ pull-up

//00000001111111111222222222233333333334444444444555555555566666666
//34567890123456789012345678901234567890123456789012345678901234567
//      |       |   .   |       |       |       |       |       |
);

  // Drive USB pins to 0 to disconnect Fomu from the host system.
  // Otherwise it would try to talk to us over USB,
  // which wouldn't work since we have no stack.
  assign usb_dp = 1'b0;
  assign usb_dn = 1'b0;
  assign usb_dp_pu = 1'b0;

  // instantiate fast clock divider
  localparam FAST_FREQ = (`SYS_CLK_FREQ >> 10);  // 46.875 kHz
  wire clk_47kHz;
  clk_div #(
    .N_DIV(10)
  ) DIV_10 (
    .clk_i(clk_48MHz),
    .clk_o(clk_47kHz)
  );

  // instantiate slow clock divider
  localparam SLOW_FREQ = (FAST_FREQ >> 8);  // 183 Hz
  wire clk_183Hz;
  clk_div #(
    .N_DIV(8)
  ) DIV_8 (
    .clk_i(clk_47kHz),
    .clk_o(clk_183Hz)
  );
/*
  clk_div #(
    .N_DIV(18)
  ) DIV_18 (
    .clk_i(clk_48MHz),
    .clk_o(clk_183Hz)
  );
*/

  // connect clock to global buffer
  localparam CLK_FREQ = SLOW_FREQ;  // 183 Hz
/*
  wire clk;
  SB_GB clk_gb (
    .USER_SIGNAL_TO_GLOBAL_BUFFER(clk_183Hz),
    .GLOBAL_BUFFER_OUTPUT(clk)
  );
*/
  assign clk = clk_183Hz;

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
  // Configure touchpad pin 1
  wire pin_1_dir = EN;
  wire pin_1_in;
  wire pin_1_out;
  SB_IO #(
    .PIN_TYPE(6'b1010_01) // tri-statable output
  ) touch_1_io (
    .PACKAGE_PIN(touch_1),
    .OUTPUT_ENABLE(pin_1_dir),
    .D_IN_0(pin_1_in),
    .D_OUT_0(pin_1_out)
  );
*/

endmodule
