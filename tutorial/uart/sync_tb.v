// sync_tb.v -- stand-alone synchronizer test

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("test_bench.vcd");
      $dumpvars(0, test_bench);
      #120;
      $finish;
    end

  // generate (slow) chip clock
  reg clk = 0;
  always
    #3 clk = !clk;

  // generate received-data signal
  reg rx = 0;
  always
    #20 rx = !rx;

  // register async rx
  reg [2:0] sync;  // receive sync-register
  always @(posedge clk)
    sync <= { sync[1:0], rx };

  // break out individual sync bits for visualization
  wire s0 = sync[0];
  wire s1 = sync[1];
  wire s2 = sync[2];

endmodule