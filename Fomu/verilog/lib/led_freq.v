/*

46.875 kHz LED Frequency Limiter (Fomu)

    +------------+
    | led_freq   |
    |            |
--->|i_led  o_led|--->
<---|o_clk       |
<---|o_stb       |
    |            |
 +->|i_clk       |
 |  +------------+

The specifications for the iCE40 FPGA used in the Fomu
say that the LED signal frequency should stay below 64kHz.
This module restricts changes in the output
to a minimum frequency of 46.875kHz, ensuring conformance.

*/

`default_nettype none

module led_freq (
  input             i_clk,              // system clock
  input             i_led,              // requested LED level
  output reg        o_clk,              // 46.875 kHz divided clock
  output reg        o_stb,              // 46.875 kHz clock strobe
  output reg        o_led               // actual LED level
);
  parameter CLK_FREQ = 48_000_000;      // Fomu clock frequency (Hz)

  // 46.875 kHz clock divider
  reg [9:0] divider;  // 1024-cycle divider
  initial divider = 0;
  always @(posedge i_clk)
    divider <= divider + 1'b1;

  // register divided clock
  initial o_clk = 1'b0;
  always @(posedge i_clk)
    o_clk <= ~divider[9];  // 46.875 kHz divided clock

  // register clock strobe
  initial o_stb = 1'b0;
  always @(posedge i_clk)
    o_stb <= (divider == 0);  // one pulse every 1024 clocks

  // hold changes for 2 strobes
  wire x_led;
  assign x_led = (o_led != i_led);  // LED level changed
  reg s1;
  initial s1 = 1'b1;
  reg s2;
  initial s2 = 1'b1;
  initial o_led = 1'b0;
  always @(posedge i_clk)
    if (s1 && s2 && x_led)
      begin
        // accept change after 2 strobes
        s1 <= 1'b0;
        s2 <= 1'b0;
        o_led <= i_led;
      end
    else if (s1 && !s2 && o_stb)
      begin
        // count 2nd strobe
        s2 <= 1'b1;
      end
    else if (!s1 && !s2 && o_stb)
      begin
        // count 1st strobe
        s1 <= 1'b1;
      end

endmodule
