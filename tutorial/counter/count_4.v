// count_4.v
//
// free-running counter
//

module count #(
  parameter WIDTH = 16                  // counter bit-width
) (
  input                  clock,         // system clock
  output reg [WIDTH-1:0] count = 0      // free-running counter
);

  genvar i;

  // countdown positive-edge transitions of each clock division
  always @(posedge clock) count[0] = !count[0];
  generate
    for (i = 0; i < WIDTH-1; i = i+1)
      always @(posedge count[i]) count[i+1] = !count[i+1];
  endgenerate

endmodule