// uart1_tb.v
//
// simulation test bench for uart.v (using serial1_rx.v)
//

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("uart1.vcd");
      $dumpvars(0, test_bench);
      #260;
      $finish;
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // simulation signals
  reg [7:0] DIN = "K";
  wire BSY;
  wire LINE;
  reg RDY = 0;
  wire VLD;
  wire BRK;
  wire [7:0] DOUT;

  // instantiate UART
  uart #(
    .CLK_FREQ(16),
    .BIT_FREQ(3)
  ) DUT (
    .clk(clk),
    .tx_data(DIN),
    .wr(!BSY),
    .busy(BSY),
    .rx_data(DOUT),
    .rd(RDY),
    .valid(VLD),
    .break(BRK),
    .rx(LINE),
    .tx(LINE)
  );

  always @(posedge clk)
    RDY <= VLD;

endmodule