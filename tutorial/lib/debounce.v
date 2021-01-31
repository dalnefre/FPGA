// debounce.v
//
// ignore transient input changes below threshold time
//

module debounce #(
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
    if (in == last)  // unchanged
      timer <= (MIN_TIME - 1);  // reset timer
    else if (timer)  // counting down
      timer <= timer - 1'b1;
    else  // new stable value
      begin
        last <= in;
        timer <= (MIN_TIME - 1);  // reset timer
      end

  assign out = last;

endmodule
