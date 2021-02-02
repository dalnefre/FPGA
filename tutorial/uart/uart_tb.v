// uart_tb.v
//
// simulation test bench for uart.v
//

`default_nettype none

module test_bench;

  localparam CLK_FREQ = 48;
  localparam BIT_FREQ = 5;

  // dump simulation signals
  initial
    begin
      $dumpfile("uart.vcd");
      $dumpvars(0, test_bench);
      #600;
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
    .CLK_FREQ(CLK_FREQ),
    .BIT_FREQ(BIT_FREQ)
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

  always @(posedge clk)
    if (!BSY)
      case (DIN)
        "K" :
          DIN <= "S";
        "S" :
          DIN <= "O";
        default :
          DIN <= "K";
      endcase

endmodule
