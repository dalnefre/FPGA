// square.v
//
// square-wave generator
//

`default_nettype none

module tone_gen #(
  parameter CLK_FREQ = 48_000_000,      // clock frequency (Hz)
  parameter OUT_FREQ = 440              // output frequency (Hz)
) (
  input            clk,                 // input clock (@ CLK_FREQ)
  output           out                  // output signal (@ OUT_FREQ)
);
  localparam CNT = CLK_FREQ / (OUT_FREQ * 2);
  localparam INIT = CNT - 1;
  localparam N = $clog2(CNT);

  reg state = 0;
  reg [N-1:0] timer = INIT;
  always @(posedge clk)
    if (timer)
      timer <= timer - 1'b1;
    else
      begin
        timer <= INIT;
        state <= !state;
      end

  assign out = state;

endmodule
