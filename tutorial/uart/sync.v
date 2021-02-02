// sync.v
//
// async input synchronizer
//

`default_nettype none

module sync #(
  parameter N = 3                       // number of DFF stages
) (
  input            clk,                 // local clock
  input            in,                  // async input signal
  output           out                  // sync output signal
);

  reg [N-1:0] sync;
  always @(posedge clk)
    sync <= { sync[N-2:0], in };

  assign out = sync[N-1];

endmodule
