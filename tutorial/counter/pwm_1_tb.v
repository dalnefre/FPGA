// pwm_1_tb.v
//
// simulation test bench for count_3.v + pwm_0.v
//

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("pwm_1.vcd");
      $dumpvars(0, test_bench);
      #250 $finish;  // stop simulation after 250 clock edges
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate counter
  wire [6:0] cnt;
  count #(
    .WIDTH(7)
  ) counter (
    ._reset(1'b1),
    .clock(clk),
    .count(cnt)
  );

  // instantiate pulse-width modulator
  wire out;
  pwm #(
    .N(3)
  ) pwm (
    .pulse(cnt[6] ? ~cnt[5:3] : cnt[5:3]),
    .count(cnt[2:0]),
    .out(out)
  );

endmodule