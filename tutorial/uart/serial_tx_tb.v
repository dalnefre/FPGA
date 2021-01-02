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
      #240;
      $finish;
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate serial transmitter
  reg [7:0] DATA;
  reg WR = 1'b0;
  wire BSY;
  wire TX;
  serial_tx #(
    .CLK_FREQ(16),
    .BIT_FREQ(3)
  ) SER_TX (
    .clk(clk),
    .wr(WR),
    .data(DATA),
    .busy(BSY),
    .tx(TX)
  );

  // character sequencer
  reg N = 0;
  always @(posedge clk)
    if (!BSY)
      if (!WR)
        begin
          DATA <= (N == 0) ? "O" : "K";
          WR <= 1'b1;
          N <= N + 1'b1;
        end
      else
        WR <= 1'b0;

endmodule