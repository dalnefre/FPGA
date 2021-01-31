// async.v
//
// register async input
//

module async #(
  parameter              N_DFF = 3        // number of DFF stages
) (
  input                  clk,             // clock signal
  input                  async_in,        // asynchronous input
  output                 sync_out         // synchronized output
);

  reg [N_DFF-1:0] sync = { (N_DFF) { 1'b0 } };  // synchronization register

  always @(posedge clk)
    sync <= { async_in, sync[N_DFF-1:1] };

  assign sync_out = sync[0];

endmodule
