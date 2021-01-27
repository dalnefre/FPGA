// count_4_tb.v
//
// simulation test bench for count_4.v
//

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("count_4.vcd");
      $dumpvars(0, test_bench);
      #100 $finish;  // stop simulation after 100 clock edges
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate device-under-test
  localparam N = 4;
  wire [N-1:0] out;
  wire b0, b1, b2, b3;
  count #(
    .WIDTH(N)
  ) DUT (
    .clock(clk),
    .count(out)
  );
  assign b0 = out[0];
  assign b1 = out[1];
  assign b2 = out[2];
  assign b3 = out[3];

endmodule
