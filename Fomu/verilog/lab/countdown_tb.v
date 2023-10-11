/*

Test Bench for countdown.v

*/

`timescale 100ns/1ns

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("countdown.vcd");
      $dumpvars(0, test_bench);
      #1200;
      $finish;
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate timer component
  localparam RANGE = 5;                 // number of countdown iterations
  localparam BITS = $clog2(RANGE);      // number of output bits
  reg [BITS-1:0] init;
  wire [BITS-1:0] cdn;
  wire wr;
  wire en;
  countdown #(
//    .INIT(RANGE-1),
    .BITS(BITS)
  ) TIMER (
    .i_clk(clk),
    .i_data(init),
    .i_wr(wr),
    .i_en(en),
    .o_data(cdn)
  );
  initial init = RANGE-1;
  //assign wr = 1'b0;                     // do not load counter
  assign wr = (cdn == 0);               // reload counter on zero
  //assign en = 1'b1;                     // enable countdown
  assign en = (cdn > 0);                // count down to zero

  // drive LEDs from counter value
  wire led_r;
  wire led_g;
  wire led_b;
  assign led_r = cdn[2];
  assign led_g = cdn[1];
  assign led_b = cdn[0];

endmodule
