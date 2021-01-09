## Fomu Counter

The traditional ["Hello, World!"](https://en.wikipedia.org/wiki/%22Hello,_World!%22_program) program
for hardware is simply blinking an LED.
We can use our basic [Counter](README.md)
to control the color of
the RGB LED on the [Fomu](../fomu.md).

```
  // clock divisions
  wire div_24MHz    = count[0];
  wire div_12MHz    = count[1];
  wire div_6MHz     = count[2];
  wire div_3MHz     = count[3];
  wire div_1_5MHz   = count[4];
  wire div_750KHz   = count[5];
  wire div_375KHz   = count[6];
  wire div_187_5KHz = count[7];

  wire div_93_75KHz = count[8];
  wire div_46_875KHz = count[9];
  wire div_23_437_5KHz = count[10];
  wire div_11_718_75KHz = count[11];
  wire div_5_859_375KHz = count[12];
  wire div_2_929_687_5KHz = count[13];
  wire div_1_464_843_75KHz = count[14];
  wire div_732_421_875Hz = count[15];

  wire div_366_210_937_5Hz = count[16];
  wire div_183_105_468_75Hz = count[17];
  wire div_91_552_734_375Hz = count[18];
  wire div_45_776_367_187_5Hz = count[19];
  wire div_22_888_183_593_75Hz = count[20];
  wire div_11_444_091_796_875Hz = count[21];
  wire div_5_722_045_898_437_5Hz = count[22];
  wire div_2_861_022_949_218_75Hz = count[23];

  wire div_1_430_511_474_609_375Hz = count[24];
  wire div_0_715_255_737_304_687_5Hz = count[25];
  wire div_0_357_627_868_652_343_75Hz = count[26];
  wire div_0_178_813_934_326_171_875Hz = count[27];
  wire div_0_089_406_967_163_085_937_5Hz = count[28];
```

```verilog
// count_3_fomu.v
//
// top-level module for Fomu PVT device (uses count_3.v)
//

// Correctly map pins for the iCE40UP5K SB_RGBA_DRV hard macro.
`define GREENPWM RGB0PWM
`define REDPWM   RGB1PWM
`define BLUEPWM  RGB2PWM

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

  // Parameters from iCE40 UltraPlus LED Driver Usage Guide, pages 19-20
  localparam RGBA_CURRENT_MODE_FULL = "0b0";
  localparam RGBA_CURRENT_MODE_HALF = "0b1";
  // Current levels in Full / Half mode
  localparam RGBA_CURRENT_04mA_02mA = "0b000001";
  localparam RGBA_CURRENT_08mA_04mA = "0b000011";
  localparam RGBA_CURRENT_12mA_06mA = "0b000111";
  localparam RGBA_CURRENT_16mA_08mA = "0b001111";
  localparam RGBA_CURRENT_20mA_10mA = "0b011111";
  localparam RGBA_CURRENT_24mA_12mA = "0b111111";

  // Instantiate iCE40 LED driver hard logic
  wire LED_r, LED_g, LED_b;
  SB_RGBA_DRV #(
    .CURRENT_MODE(RGBA_CURRENT_MODE_HALF),
//    .RGB0_CURRENT(RGBA_CURRENT_08mA_04mA),
    .RGB0_CURRENT(RGBA_CURRENT_16mA_08mA),  // green needs more current
    .RGB1_CURRENT(RGBA_CURRENT_08mA_04mA),
    .RGB2_CURRENT(RGBA_CURRENT_08mA_04mA)
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

  // Connect counter bits to LED
  assign LED_r = out[N-2];  // bit 26 ( ~2.8s cycle, ~1.4s on/off)
  assign LED_g = out[N-3];  // bit 25 ( ~1.4s cycle, ~0.7s on/off)
  assign LED_b = out[N-1];  // bit 27 ( ~5.6s cycle, ~2.8s on/off)

endmodule
```

The following block diagram illustrates our final design.

```
  +-------------------------------------------------------------------------+
  | fomu_pvt                                                                |
  |                                                          0 --> usb_dp_pu|--
  |                                                          0 -----> usb_dp|--
  |                                                          0 -----> usb_dn|--
  |                                                                         |
  |       clk_gb                                    RGBA_DRIVER             |
  |       +------------------------------+          +---------------+       |
  |       | SB_GB                        |          | SB_RGBA_DRV   |       |
  |       |                              |          |               |       |
->|clki ->|USER_SIGNAL_TO_GLOBAL_BUFFER  |     1 -->|CURREN         |       |
  |       |                              |     1 -->|RGBLEDEN       |       |
  |       |          GLOBAL_BUFFER_OUTPUT|-+        |               |       |
  |       |                              | |   +--->|RGB0PWM    RGB0|-> rgb0|--
  |       +------------------------------+ |   |+-->|RGB1PWM    RGB1|-> rgb1|--
  |                                        |   ||+->|RGB2PWM    RGB2|-> rgb2|--
  |  +-----------------clk-----------------+   |||  |               |       |
  |  |                                         |||  +---------------+       |
  |  |       counter                           |||                          |
  |  |       +--------------+                  |||                          |
  |  |       | count        |                  |||                          |
  |  |       |              | 28     out       |||                          |
  |  |  1 -->|_reset   count|--/--+--[0]-x     |||                          |
  |  |       |              |     +-  :        |||                          |
  |  +------>|clock      msb|-x   +--[25]------+|| LED_g                    |
  |          |              |     +--[26]-------+| LED_r                    |
  |          +--------------+     +--[27]--------+ LED_b                    |
  |                                                                         |
  +-------------------------------------------------------------------------+
```

### Using Individual Bits

One common use of a counter
is to "pre-scale" the clock signal
to a lower frequency.
Each bit of the counter
divides the frequency in half.
For example,
if our system clock was 48MHz
(as it is on the [Fomu](../fomu.md))
and we set the counter `WIDTH` to `4`,
the most-significant bit (MSB) of the `count`
would toggle at a frequency of 3MHz.

```verilog
// count_3.v
//
// free-running counter
//

module count #(
  parameter INIT = 0,                   // initial value
  parameter WIDTH = 16                  // counter bit-width
) (
  input                  _reset,        // active-low reset
  input                  clock,         // system clock
  output                 msb,           // MSB of counter (pre-scaler)
  output reg [WIDTH-1:0] count = INIT   // free-running counter
);

  // count positive-edge transitions of the clock
  always @(posedge clock)
    count <= _reset ? count + 1'b1 : INIT;

  assign msb = count[WIDTH-1];

endmodule
```

```verilog
// pwm_0.v
//
// pulse-width modulation
//

module pwm #(
  parameter P = 0,                      // phase offset
  parameter N = 8                       // counter resolution
) (
  input          [N-1:0] pulse,         // pulse threshold
  input          [N-1:0] count,         // duty-cycle counter
  output                 out            // on/off output signal
);

  wire [N-1:0] mod = (count + P);
  assign out = pulse < mod;

endmodule
```

Synthesis, Place and Route, Package, and Deploy.

```
$ yosys -p 'synth_ice40 -json fomu_pvt.json' count_3.v count_3_fomu.v
$ nextpnr-ice40 --up5k --package uwg30 --pcf ../../Fomu/pcf/fomu-pvt.pcf --json fomu_pvt.json --asc fomu_pvt.asc
$ icepack fomu_pvt.asc fomu_pvt.bit
$ cp fomu_pvt.bit fomu_pvt.dfu
$ dfu-suffix -v 1209 -p 70b1 -a fomu_pvt.dfu
$ dfu-util -D fomu_pvt.dfu
```
