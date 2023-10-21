/*

Physical Test Bench

*/

`default_nettype none

`include "alloc.v"

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

  // sequence counter
  reg [23:0] cnt;
  initial cnt = 0;
  always @(posedge clk)
    cnt <= cnt + 1'b1;
  reg [3:0] seq;
  initial seq = 0;
  always @(posedge clk)
    if (&cnt[19:0])  // all 1's
      seq <= cnt[23:20];
    else
      seq <= 4'b0000;

  // FIXME: move definitions to an include file?
  localparam UNDEF  = 16'h0000;         // undefined value

  // allocation port
  wire alloc_stb;  // allocation request
  assign alloc_stb = seq[0];
  wire [15:0] alloc_addr;

  // free port
  wire free_stb;  // free request
  assign free_stb = seq[2];
  reg [15:0] free_addr;
  initial free_addr = 16'h5001;

  // error condition
  wire error;

  // instantiate allocator
  wire free_done;
  alloc #(
    .ADDR_SZ(4)
  ) ALLOC (
    .i_clk(clk),
    .i_alloc(alloc_stb),
    .i_data(UNDEF),
    .o_addr(alloc_addr),
    .i_free(free_stb),
    .i_addr(free_addr),
    .i_rd(1'b0),
    .i_wr(1'b0),
    .o_err(error)
  );

  // drive LEDs
  assign led_r = error;
  assign led_g = |alloc_addr[7:0];
  assign led_b = free_done;

endmodule
