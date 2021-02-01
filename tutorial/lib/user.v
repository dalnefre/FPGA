// user.v
//
// example user design
//

`default_nettype none

module top #(
  parameter         CHIP_FREQ = 48_000_000, // chip clock frequency
  parameter         FAST_FREQ = 46_875,     // fast clock frequency
  parameter         SLOW_FREQ = 183         // slow clock frequency
) (
  input             chip_clk,               // chip clock
  input             fast_clk,               // fast clock
  input             slow_clk,               // slow clock
  output            led_r,                  // red LED signal
  output            led_g,                  // green LED signal
  output            led_b                   // blue LED signal
);

  // select clock
  localparam CLK_FREQ = SLOW_FREQ;
  wire clk = slow_clk;

  // countdown timer
  localparam TIMER_FREQ = (CLK_FREQ / 5);  // 5 Hz update rate = 0.2 seconds
  localparam N_TIMER = $clog2(TIMER_FREQ);
  reg [N_TIMER-1:0] timer = 0;
  always @(posedge clk)
    timer <= timer ? timer - 1'b1 : (TIMER_FREQ - 1);

  // drive LEDs through rainbow sequence
  reg [2:0] state = 3'b000;
  always @(posedge clk)
    if (!timer)  // take action when timer reaches zero
      case (state)
        3'b000 :
          state <= 3'b001;
        3'b001 :
          state <= 3'b011;
        3'b011 :
          state <= 3'b010;
        3'b010 :
          state <= 3'b110;
        3'b110 :
          state <= 3'b100;
        3'b100 :
          state <= 3'b101;
        3'b101 :
          state <= 3'b001;
        default :
          state <= 3'b000;
      endcase

  assign led_r = state[2];
  assign led_g = state[1];
  assign led_b = state[0];

endmodule
