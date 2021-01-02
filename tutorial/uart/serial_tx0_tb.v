// serial_tx0_tb.v
//
// simulation test bench for baud_gen.v + serial_tx0.v
//

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("test_bench.vcd");
      $dumpvars(0, test_bench);
      #120;
      $finish;
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate baud-rate generator
  wire bit;
  baud_gen #(
    .CLK_FREQ(16),
    .BIT_FREQ(3)
  ) BD_GEN (
    .clk(clk),
    .zero(bit)
  );

  // instantiate serial transmitter
  wire TX;
  serial_tx SER_TX (
    .sys_clk(clk),
    .bit_clk(bit),
    .data("K"),
    .tx(TX)
  );

endmodule