// baud_gen_tb.v
//
// simulation test bench for baud_gen.v
//

`default_nettype none

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("baud_gen.vcd");
      $dumpvars(0, test_bench);
      #50;
      $finish;
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate device-under-test
  wire tick;
  baud_gen #(
    .CLK_FREQ(16),
    .BIT_FREQ(3)
  ) DUT (
    .clk(clk),
    .zero(tick)
  );

endmodule
