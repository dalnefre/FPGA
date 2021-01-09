// pwm_fomu.v
//
// top-level module for Fomu PVT device (uses count_3.v and pwm_0.v)
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
  localparam N = 29;
  wire [N-1:0] cnt;
  count #(
    .WIDTH(N)
  ) counter (
    ._reset(1'b1),
    .clock(clk),
    .count(cnt)
  );

  // Calculate PWM levels
  wire [1:0] phase = cnt[28:27];  // ~11.2s
  wire [7:0] ramp = cnt[26:19];  // ~2.8s
  wire [7:0] pulse_r = (phase[1]
    ? (phase[0] ? 8'h00 : 8'hFF - ramp[7:0])
    : (phase[0] ? 8'hFF : ramp[7:0])
  );
  wire [7:0] pulse_g = (phase[1]
    ? (phase[0] ? 8'hFF - ramp[7:0] : 8'hFF)
    : (phase[0] ? ramp[7:0] : 8'h00)
  );
  wire [7:0] pulse_b = (phase[1]
    ? (phase[0] ? ramp[7:0] : 8'h00)
    : (phase[0] ? 8'h00 : 8'hFF - ramp[7:0])
  );
/*
  reg [7:0] pulse_r;  // PWM level for Red LED
  reg [7:0] pulse_g;  // PWM level for Green LED
  reg [7:0] pulse_b;  // PWM level for Blue LED
  always @(posedge clk)
    case (phase)
      2'b00 :
        begin
          pulse_r <= ramp[7:0];  // ramp up
          pulse_g <= 8'h00;  // off
          pulse_b <= 8'hFF - ramp[7:0];  // ramp down
        end
      2'b01 :
        begin
          pulse_r <= 8'hFF;  // full on
          pulse_g <= ramp[7:0];  // ramp up
          pulse_b <= 8'h00;  // off
        end
      2'b10 :
        begin
          pulse_r <= 8'hFF - ramp[7:0];  // ramp down
          pulse_g <= 8'hFF;  // full on
          pulse_b <= 8'h00;  // off
        end
      2'b11 :
        begin
          pulse_r <= 8'h00;  // off
          pulse_g <= 8'hFF - ramp[7:0];  // ramp down
          pulse_b <= ramp[7:0];  // ramp up
        end
      default :  // unexpected state
        begin
          pulse_r <= 8'h00;  // off
          pulse_g <= 8'h00;  // off
          pulse_b <= 8'h00;  // off
        end
    endcase
*/

  // Instantiate pulse-width modulators
  pwm pwm_r (
    .pulse(pulse_r),
    .count(cnt[16:9]),  // 46.875KHz
    .out(LED_r)
  );
  pwm pwm_g (
    .pulse(pulse_g),
    .count(cnt[16:9]),  // 46.875KHz
    .out(LED_g)
  );
  pwm pwm_b (
    .pulse(pulse_b),
    .count(cnt[16:9]),  // 46.875KHz
    .out(LED_b)
  );

endmodule