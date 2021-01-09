// pwm_0_tb.v
//
// simulation test bench for count_3.v + pwm_0.v
//

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("test_bench.vcd");
      $dumpvars(0, test_bench);
      #120 $finish;  // stop simulation after 120 clock edges
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate counter
  wire [4:0] cnt;
  count #(
    .WIDTH(5)
  ) counter (
    ._reset(1'b1),
    .clock(clk),
    .count(cnt)
  );

  // instantiate pulse-width modulator
  wire out;
  pwm #(
    .N(2)
  ) pwm (
    .pulse(cnt[4:3]),
    .count(cnt[1:0]),
    .out(out)
  );

endmodule