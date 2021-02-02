// serial_tx_tb.v
//
// simulation test bench for serial_tx.v
//

`default_nettype none

module test_bench;

  localparam CLK_FREQ = 48;
  localparam BIT_FREQ = 5;

  // dump simulation signals
  initial
    begin
      $dumpfile("serial_tx.vcd");
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
    .CLK_FREQ(CLK_FREQ),
    .BIT_FREQ(BIT_FREQ)
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
