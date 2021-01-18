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
  reg [7:0] DIN = "K";
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
    .wr(!BSY),
    .din(DIN),
    .busy(BSY),
    .tx(LINE),
    .rx(LINE),
    .ready(RDY),
    .break(BRK),
    .dout(DOUT)
  );

endmodule