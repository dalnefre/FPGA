// count_3_tb.v
//
// simulation test bench for count_3.v
//

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("test_bench.vcd");
      $dumpvars(0, test_bench);
      #5 _rst <= 1;  // come out of reset after 5 clock edges
      #85 _rst <= 0;  // re-assert reset after 85 clock edges
      #10 $finish;  // stop simulation after 10 clock edges
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate device-under-test
  localparam N = 4;
  wire [N-1:0] out;
  wire b0, b1, b2, b3;
  reg _rst = 0;
  count #(
    .WIDTH(N)
  ) DUT (
    ._reset(_rst),
    .clock(clk),
    .count(out)
  );
  assign b0 = out[0];
  assign b1 = out[1];
  assign b2 = out[2];
  assign b3 = out[3];

endmodule