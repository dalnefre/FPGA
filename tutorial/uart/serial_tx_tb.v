// serial_tx_tb.v
//
// simulation test bench for baud_gen.v + serial_tx.v
//

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("test_bench.vcd");
      $dumpvars(0, test_bench);
      #13;
      WR = 1'b1;
      #2;
      WR = 1'b0;
      #150;
      $finish;
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate serial transmitter
  wire TX;
  reg WR = 1'b0;
  serial_tx SER_TX (
    .clk(clk),
    .wr(WR),
    .data("K"),
    .tx(TX)
  );

endmodule