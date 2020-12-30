// baud_gen.v
//
// baud-rate generator
//

module baud_gen #(
  parameter CLK_FREQ = 48_000_000,      // clock frequency (Hz)
  parameter BIT_FREQ = 115_200          // baud rate (bits per second)
) (
  input            clk,                 // input clock
  output           zero                 // output tick
);
  localparam CNT = CLK_FREQ / BIT_FREQ;
  localparam N = $clog2(CNT);

  reg [N-1:0] cnt = (CNT - 1);
  always @(posedge clk)
    cnt <= zero ? (CNT - 1) : cnt - 1'b1;

  assign zero = !cnt;

endmodule