// user_tb.v
//
// simulation test bench for user.v
//

module test_bench;

  localparam CLK_FREQ = 256;
  localparam N_DIV = 3;

  // dump simulation signals
  initial
    begin
      $dumpfile("user.vcd");
      $dumpvars(0, test_bench);
      #(CLK_FREQ * 2);  // run for 1 "second"
      $finish;  // stop simulation
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate clock divider
  wire div;  // divided clock
  clk_div #(
    .N_DIV(N_DIV)
  ) DIV (
    .clk_i(clk),
    .clk_o(div)
  );

  // instantiate device-under-test
  wire led_r;
  wire led_g;
  wire led_b;
  top #(
    .CLK_FREQ(CLK_FREQ >> N_DIV)
  ) DUT (
    .clk(div),
    .led_r(led_r),
    .led_g(led_g),
    .led_b(led_b)
  );

endmodule
