/*

Serial UART composed of separate RX and TX modules

*/

`default_nettype none

module top (
  input             clki,               // 48MHz oscillator input on Fomu-PVT
  output            rgb0,               // RGB LED pin 0 (**DO NOT** drive directly)
  output            rgb1,               // RGB LED pin 1 (**DO NOT** drive directly)
  output            rgb2,               // RGB LED pin 2 (**DO NOT** drive directly)
  output            user_1,             // User I/O Pad #1 (nearest to notch)
  output            user_2,             // User I/O Pad #2
  input             user_3,             // User I/O Pad #3
  output            user_4,             // User I/O Pad #4
  output            usb_dp,             // USB D+
  output            usb_dn,             // USB D-
  output            usb_dp_pu           // USB D+ pull-up
);
  parameter CLK_FREQ = 48_000_000;      // clock frequency (Hz)
  parameter BAUD_RATE = 115_200;        // baud rate (bits per second)

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
  assign user_1 = 1'b0;                 // GND
//  assign user_2 = 1'b0;                 // TX
//  assign user_3 = 1'b1;                 // RX
  assign user_4 = 1'b1;                 // 3v3

  localparam SB_IO_TYPE_SIMPLE_OUTPUT = 6'b011000;
  wire o_data;                          // TX
  SB_IO #(
    .PIN_TYPE(SB_IO_TYPE_SIMPLE_OUTPUT)
  ) user_2_io (
    .PACKAGE_PIN(user_2),
    .OUTPUT_ENABLE(1'b1),  // FIXME: not needed?
    .OUTPUT_CLK(clk),
    .D_OUT_0(o_data),
  );

  localparam SB_IO_TYPE_SIMPLE_INPUT = 6'b000001;
  wire i_data;                          // RX
  SB_IO #(
    .PIN_TYPE(SB_IO_TYPE_SIMPLE_INPUT),
    .PULLUP(1'b1)
  ) user_3_io (
    .PACKAGE_PIN(user_3),
    .OUTPUT_ENABLE(1'b0),  // FIXME: not needed?
    .INPUT_CLK(clk),
    .D_IN_0(i_data),
  );

  // instantiate serial transmitter
  wire tx_wr;
  reg [7:0] tx_data;
  wire tx_busy;
  wire uart_tx;
  serial_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
  ) SER_TX (
    .i_clk(clk),
    .i_wr(tx_wr),
    .i_data(tx_data),
    .o_busy(tx_busy),
    .o_tx(uart_tx)
  );

  // connect serial_tx
  assign tx_wr = 1'b1;  // perpetual write-request
  initial tx_data = "K";  // transmit unending stream of "K" characters
  assign o_data = uart_tx;
  assign led_r = uart_tx;  // FIXME: may need to "stretch" this signal

endmodule
