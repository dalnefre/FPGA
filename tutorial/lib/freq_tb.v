// freq_tb.v
//
// simulation test bench for freq.v
//

`default_nettype none

module test_bench;

  localparam CLK_FREQ = 256;

  // dump simulation signals
  initial
    begin
      $dumpfile("freq.vcd");
      $dumpvars(0, test_bench);
      #(CLK_FREQ * 2);  // run for 1 "second"
      $finish;  // stop simulation
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate device-under-test
  wire led;
  freq #(
//    .INIT(1),
    .N_CNT(4)
  ) DUT (
    .clk(clk),
    .lo(4'h1),
    .hi(4'h2),
    .out(led)
  );

endmodule
