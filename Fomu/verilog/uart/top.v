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
  wire o_tx;                            // TX
  SB_IO #(
    .PIN_TYPE(SB_IO_TYPE_SIMPLE_OUTPUT)
  ) user_2_io (
    .PACKAGE_PIN(user_2),
    .OUTPUT_ENABLE(1'b1),  // FIXME: not needed?
    .OUTPUT_CLK(clk),
    .D_OUT_0(o_tx),
  );

  localparam SB_IO_TYPE_SIMPLE_INPUT = 6'b000001;
  wire i_rx;                            // RX
  SB_IO #(
    .PIN_TYPE(SB_IO_TYPE_SIMPLE_INPUT),
    .PULLUP(1'b1)
  ) user_3_io (
    .PACKAGE_PIN(user_3),
    .OUTPUT_ENABLE(1'b0),  // FIXME: not needed?
    .INPUT_CLK(clk),
    .D_IN_0(i_rx),
  );

  // instantiate serial receiver
  wire uart_rx;
  wire rx_wr;
  wire [7:0] rx_data;
  serial_rx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
  ) SER_RX (
    .i_clk(clk),
    .i_rx(uart_rx),
    .o_wr(rx_wr),
    .o_data(rx_data)
  );
  assign uart_rx = i_rx;
  assign led_r = !uart_rx;  // FIXME: may need to "stretch" this signal

  // instantiate fifo
  wire wr;
  wire full;
  wire rd;
  wire empty;
  fifo #(
    .N_ADDR(3)
  ) FIFO (
    .i_clk(clk),
    .i_wr(wr),
    .i_data(rx_data),
    .o_full(full),
    .i_rd(rd),
    .o_data(tx_data),
    .o_empty(empty)
  );
  assign wr = !full && rx_wr;  // drop characters if fifo is full
  assign rd = !empty && !tx_busy;
  assign tx_wr = rd;

  // instantiate serial transmitter
  wire tx_wr;
  wire [7:0] tx_data;
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
  assign o_tx = uart_tx;
  assign led_g = !uart_tx;  // FIXME: may need to "stretch" this signal

endmodule
