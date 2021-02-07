// square_tb.v
//
// simulation test bench for square.v
//

`default_nettype none

module test_bench;

  localparam CLK_FREQ = 48;
  localparam OUT_FREQ = 8;

  // dump simulation signals
  initial
    begin
      $dumpfile("square.vcd");
      $dumpvars(0, test_bench);
      #(2 * CLK_FREQ);  // run for 1 simulated second
      $finish;  // stop simulation
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate device-under-test
  wire out;
  tone_gen #(
    .CLK_FREQ(CLK_FREQ),
    .OUT_FREQ(OUT_FREQ)
  ) DUT (
    .clk(clk),
    .out(out)
  );

endmodule
