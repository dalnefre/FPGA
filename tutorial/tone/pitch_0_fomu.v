// pitch_0_fomu.v
//
// top-level module for Fomu PVT device
//
// requires:
//    pitch.v
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

  // Drive USB pins to 0 to disconnect Fomu from the host system.
  // Otherwise it would try to talk to us over USB,
  // which wouldn't work since we have no stack.
  assign usb_dp = 1'b0;
  assign usb_dn = 1'b0;
  assign usb_dp_pu = 1'b0;

  // Connect to system clock (with buffering)
  wire clk;  // 48MHz system clock
  SB_GB clk_gb (
    .USER_SIGNAL_TO_GLOBAL_BUFFER(clk_48MHz),
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
    .RGB0(rgb_0),
    .RGB1(rgb_1),
    .RGB2(rgb_2)
  );

  // 28-bit counter
  localparam NC = 28;
  reg [NC-1:0] count;
  always @(posedge clk)
    count <= count + 1'b1;

  // Instantiate tone generator
  reg [3:0] pitch = `C;
  reg [2:0] octave = 4;
  wire spkr;
  tone_gen #(
    .CLK_FREQ(`SYS_CLK_FREQ)
  ) TONE (
    .clk(clk),
    .pitch(pitch),
    .octave(octave),
    .out(spkr)
  );

  wire EN;  // enable tone
  assign EN = count[NC-2];  // bit 26 ( ~2.8s cycle, ~1.4s on/off)

  // Configure user pin 1
  wire pin_1_en = EN;
  wire pin_1_in;
  wire pin_1_out;
  SB_IO #(
    .PIN_TYPE(6'b1010_01) // tri-statable output
  ) user_1_io (
    .PACKAGE_PIN(user_1),
    .OUTPUT_ENABLE(pin_1_en),
    .D_IN_0(pin_1_in),
    .D_OUT_0(pin_1_out)
  );

  // Connect user pins
  assign pin_1_out = spkr;  // "speaker" pin
  assign user_2 = 1'b1;
  assign user_3 = 1'b1;
  assign user_4 = 1'b0;  // "ground" pin

  // Connect counter bits to LED
  assign LED_r = count[NC-2];  // bit 26 ( ~2.8s cycle, ~1.4s on/off)
  assign LED_g = count[NC-1];  // bit 27 ( ~5.6s cycle, ~2.8s on/off)
  assign LED_b = count[NC-3];  // bit 25 ( ~1.4s cycle, ~0.7s on/off)

endmodule