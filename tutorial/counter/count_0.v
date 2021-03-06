// count_0.v -- stand-alone counter test

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("count_0.vcd");
      $dumpvars(0, test_bench);
      #50;  // after 50 clock edges...
      $display("final count = %d", count);
      $finish;  // stop simulation
    end

  // generate simulated chip clock
  reg clock = 0;
  always
    #1 clock = !clock;

  // count positive-edge transitions of the clock
  reg [3:0] count = 0;  // free-running counter
  always @(posedge clock)
    count <= count + 1'b1;

endmodule
