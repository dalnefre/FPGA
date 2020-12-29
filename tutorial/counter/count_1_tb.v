// count_1_tb.v
//
// simulation test bench for count_1.v
//

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("test_bench.vcd");
      $dumpvars(0, test_bench);
      #50;  // after 50 clock edges...
      $display("final count = %d", out);
      $finish;  // stop simulation
    end

  // generate simulated chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate device-under-test (DUT)
  wire [3:0] out;
  count DUT (
    .clock(clk),
    .count(out)
  );

endmodule