// count_1.v
//
// free-running counter
//

module count (
  input  wire      clock,       // system clock
  output reg [3:0] count = 0    // free-running counter
);

  // count positive-edge transitions of the clock
  always @(posedge clock)
    count <= count + 1'b1;

endmodule