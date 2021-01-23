// uart_tb.v
//
// simulation test bench for uart.v
//

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("uart.vcd");
      $dumpvars(0, test_bench);
      #260;
      $finish;
    end

  // generate chip clock
  reg CLK = 0;
  always
    #1 CLK = !CLK;

  // simulation signals
  wire [7:0] DIN;
  wire BSY;
  wire LINE;
  wire RDY;
  wire BRK;
  wire [7:0] DOUT;

  // instantiate UART
  uart #(
    .CLK_FREQ(16),
    .BIT_FREQ(3)
  ) DUT (
    .clk(CLK),
    .tx_data(DOUT),
    .wr(!BSY),
    .busy(BSY),
    .rx_data(DIN),
    .rd(RDY),
//    .valid(VLD),
    .break(BRK),
    .rx(LINE),
    .tx(LINE)
  );

endmodule