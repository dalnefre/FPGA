// uart_0_fomu.v
//
// top-level module for Fomu PVT device
//
// requires:
//    uart.v
//    serial_rx.v
//    serial_tx.v
//

`include "fomu_pvt.vh"

module fomu_pvt (
  input  clki,      // 48MHz oscillator input

  output rgb0,      // RGB LED pin 0 (**DO NOT** drive directly)
  output rgb1,      // RGB LED pin 1 (**DO NOT** drive directly)
  output rgb2,      // RGB LED pin 2 (**DO NOT** drive directly)

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
  reg clk_24MHz = 0;
  always @(posedge clki)
    clk_24MHz = !clk_24MHz;
  wire clk;  // system clock
  localparam CLK_FREQ = (`SYS_CLK_FREQ >> 1);  // divide-by-2
  SB_GB clk_gb (
    .USER_SIGNAL_TO_GLOBAL_BUFFER(clk_24MHz),
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

  // Configure user pin 2
  wire pin_2_en = 1'b1;  // output
  wire pin_2_in;
  wire pin_2_out;
  SB_IO #(
    .PIN_TYPE(6'b1010_01) // tri-statable output
  ) user_2_io (
    .PACKAGE_PIN(user_2),
    .OUTPUT_ENABLE(pin_2_en),
    .D_IN_0(pin_2_in),
    .D_OUT_0(pin_2_out)
  );

  // Configure user pin 3
  wire pin_3_en = 1'b0;  // input
  wire pin_3_in;
  wire pin_3_out;
  SB_IO #(
    .PIN_TYPE(6'b1010_01) // tri-statable output
  ) user_3_io (
    .PACKAGE_PIN(user_3),
    .OUTPUT_ENABLE(pin_3_en),
    .D_IN_0(pin_3_in),
    .D_OUT_0(pin_3_out)
  );

  // Connect user pins
  assign user_1 = 0;  // "ground" pin
  assign pin_2_out = TX;
  assign RX = pin_3_in;
  assign user_4 = 0;  // "ground" pin

  // Serial I/O interface
  wire TX;  // serial data transmit
  wire RX;  // serial data receive

  wire [7:0] RXD;
  reg RD = 0;
  wire VLD;
  wire BRK;
  reg [7:0] TXD;
  reg WR = 0;
  wire BSY;

  localparam BAUD_RATE = 115_200;
//  localparam BAUD_RATE = 9_600;

  // instantiate UART
  uart #(
    .CLK_FREQ(CLK_FREQ),
    .BIT_FREQ(BAUD_RATE)
  ) DUT (
    .clk(clk),
    .rx_data(RXD),
    .rd(RD),
    .valid(VLD),
    .break(BRK),
    .tx_data(TXD),
    .wr(WR),
    .busy(BSY),
    .rx(RX),
    .tx(TX)
  );

  assign LED_r = !RX;  // connect red LED to UART RX signal
  assign LED_g = !TX;  // connect green LED to UART TX signal
  assign LED_b = BRK;  // connect blue LED to UART BREAK signal

  always @(posedge clk)
    begin
      if (VLD)
        begin
          RD <= 1;  // ack input
          if (((RXD >= "A") && (RXD <= "Z"))
          ||  ((RXD >= "a") && (RXD <= "z")))
            TXD <= (RXD ^ 8'h20);  // swap case
          else
            TXD <= RXD;  // copy input to output
          WR <= 1;  // request output
        end
      else
        RD <= 0;
      if (WR && BSY)
        WR <= 0;  // output accepted
    end

/*
         +--------------+
         | uart         |
         |              |
    ---->|clk           |
         |              |
      8  |              |
    --/->|tx_data     tx|---->
    ---->|wr            |
    <----|busy          |
         |              |
      8  |              |
    <-/--|rx_data     rx|<----
    ---->|rd            |
    <----|valid         |
    <----|break         |
         |              |
         +--------------+

module usb_uart (
  input clk_48mhz,
  input resetq,
  output host_presence,

  // USB pins
  inout  pin_usb_p,
  inout  pin_usb_n,

  // UART interface
  input  uart_wr,
  input  uart_rd,
  input  [7:0] uart_tx_data,
  output [7:0] uart_rx_data,
  output uart_busy,
  output uart_valid
);
*/

/*
  // 28-bit counter
  localparam N = 28;
  reg [N-1:0] count;
  always @(posedge clk)
    count <= count + 1'b1;

  // Connect counter bits to LED
  assign LED_r = count[N-2];  // bit 26 (~2.8s cycle, ~1.4s on/off @48Mhz)
  assign LED_g = count[N-3];  // bit 25 (~1.4s cycle, ~0.7s on/off @48Mhz)
  assign LED_b = count[N-1];  // bit 27 (~5.6s cycle, ~2.8s on/off @48Mhz)
*/

endmodule