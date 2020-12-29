// count_2_tb.v
//
// simulation test bench for count_2.v
//

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("test_bench.vcd");
      $dumpvars(0, test_bench);
      #5 _rst = 1;  // come out of reset after 5 clock edges
      #45 _rst = 0;  // re-assert reset after 45 clock edges
      #10 $finish;  // stop simulation after 10 clock edges
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate device-under-test
  localparam N = 4;
  wire [N-1:0] out;
  reg _rst = 0;
  count #(
    .WIDTH(N)
  ) DUT (
    ._reset(_rst),
    .clock(clk),
    .count(out)
  );

endmodule