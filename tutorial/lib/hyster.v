// hyster.v
//
// input change hysteresis with minumum hold time (pulse stretching)
//

module hyster #(
  parameter              MIN_TIME = 256   // minimum stable clock-cycles
) (
  input                  clk,             // clock signal
  input                  in,              // noisy input
  output                 out              // stable output
);

  reg last = 0;  // last stable value

  // stability timer
  localparam N_TIMER = $clog2(MIN_TIME);
  reg [N_TIMER-1:0] timer = 0;

  always @(posedge clk)
    if (timer)  // counting down (hold)
      timer <= timer - 1'b1;
    else if (in != last)  // change
      begin
        last <= in;
        timer <= (MIN_TIME - 1);  // reset timer
      end

  assign out = last;

endmodule
