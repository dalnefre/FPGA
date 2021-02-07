// count_3_fomu.v
//
// top-level module for Fomu PVT device (uses count_3.v)
//

`default_nettype none

`include "fomu_pvt.vh"

module fomu_pvt (
  input  clki,      // 48MHz oscillator input
  output rgb0,      // RGB LED pin 0 (**DO NOT** drive directly)
  output rgb1,      // RGB LED pin 1 (**DO NOT** drive directly)
  output rgb2,      // RGB LED pin 2 (**DO NOT** drive directly)
  output usb_dp,    // USB D+
  output usb_dn,    // USB D-
  output usb_dp_pu  // USB D+ pull-up
);

  // Drive USB pins to 0 to disconnect Fomu from the host system.
  // Otherwise it would try to talk to us over USB,
  // which wouldn't work since we have no stack.
  assign usb_dp = 1'b0;
  assign usb_dn = 1'b0;
  assign usb_dp_pu = 1'b0;

  // Connect to system clock (with buffering)
  wire clk;  // 48MHz system clock
  SB_GB clk_gb (
    .USER_SIGNAL_TO_GLOBAL_BUFFER(clki),
    .GLOBAL_BUFFER_OUTPUT(clk)
  );

  // Instantiate iCE40 LED driver hard logic
  wire LED_r, LED_g, LED_b;
  SB_RGBA_DRV #(
    .CURRENT_MODE(`RGBA_CURRENT_MODE_HALF),
//    .RGB0_CURRENT(`RGBA_CURRENT_08mA_04mA),
    .RGB0_CURRENT(`RGBA_CURRENT_16mA_08mA),  // green needs more current
    .RGB1_CURRENT(`RGBA_CURRENT_08mA_04mA),
    .RGB2_CURRENT(`RGBA_CURRENT_08mA_04mA)
  ) RGBA_DRIVER (
    .CURREN(1'b1),
    .RGBLEDEN(1'b1),
    .`REDPWM(LED_r),    // Red
    .`GREENPWM(LED_g),  // Green
    .`BLUEPWM(LED_b),   // Blue
    .RGB0(rgb0),
    .RGB1(rgb1),
    .RGB2(rgb2)
  );

/*
  // Instantiate counter
  localparam N = 28;
  wire [N-1:0] out;
  count #(
    .WIDTH(N)
  ) counter (
    ._reset(1'b1),
    .clock(clk),
    .count(out)
  );
*/
  // Embed counter
  localparam N = 28;
  reg [N-1:0] out = 0;
  always @(posedge clk)
    out <= out + 1'b1;

  // Connect counter bits to LED
  assign LED_r = out[N-2];  // bit 26 ( ~2.8s cycle, ~1.4s on/off)
  assign LED_g = out[N-3];  // bit 25 ( ~1.4s cycle, ~0.7s on/off)
  assign LED_b = out[N-1];  // bit 27 ( ~5.6s cycle, ~2.8s on/off)

endmodule