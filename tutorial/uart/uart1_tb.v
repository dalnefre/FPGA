// uart1_tb.v
//
// simulation test bench for uart.v (using serial1_rx.v)
//

`default_nettype none

module test_bench;

  localparam CLK_FREQ = 48;
  localparam BIT_FREQ = 5;

  // dump simulation signals
  initial
    begin
      $dumpfile("uart1.vcd");
      $dumpvars(0, test_bench);
      #600;
      $finish;
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // Serial I/O interface
  wire TX;  // serial data transmit
  wire RX;  // serial data receive

  wire [7:0] RXD;
  reg RD = 0;
  wire VLD;
  wire BRK;
  reg [7:0] TXD;
  reg WR = 0;
  wire BSY;

  // instantiate UART
  uart #(
    .CLK_FREQ(CLK_FREQ),
    .BIT_FREQ(BIT_FREQ)
  ) DUT (
    .clk(clk),
    .rx_data(RXD),
    .rd(RD),
    .valid(VLD),
    .break(BRK),
    .tx_data(TXD),
    .wr(WR),
    .busy(BSY),
    .rx(RX),
    .tx(TX)
  );

  // lookback data
  always @(posedge clk)
    begin
      if (VLD)
        begin
          RD <= 1;  // ack input
          TXD <= RXD;  // copy input to output
          WR <= 1;  // request output
        end
      else
        RD <= 0;
      if (WR && BSY)
        WR <= 0;  // output accepted
    end

  // instantiate test-data transmitter
  wire td_busy;
  serial_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BIT_FREQ(BIT_FREQ)
  ) TST_TX (
    .clk(clk),
    .data(DIN),
    .wr(!td_busy),
    .busy(td_busy),
    .tx(RX)
  );

  // simulation signals
  reg [7:0] DIN = "K";
  always @(posedge clk)
    if (!td_busy)
      case (DIN)
        "K" :
          DIN <= "S";
        "S" :
          DIN <= "O";
        default :
          DIN <= "K";
      endcase

endmodule
