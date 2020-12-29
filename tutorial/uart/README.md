## Serial UART

### Links

 * [UART (Wikipedia)](https://en.wikipedia.org/wiki/Universal_asynchronous_receiver-transmitter)
 * [Serial Communication (sparkfun)](https://learn.sparkfun.com/tutorials/serial-communication)
 * [UART vs I2C vs SPI (Seeed Studio)](https://www.seeedstudio.com/blog/2019/09/25/uart-vs-i2c-vs-spi-communication-protocols-and-uses/)
 * [Metastability (Wikipedia)](https://en.wikipedia.org/wiki/Metastability_(electronics))
 * [Null Modem (Wikipedia)](https://en.wikipedia.org/wiki/Null_modem)

### Code

```verilog
// uart.v
//
// serial UART (8N1)
//

`define IDLE_BIT  1'b1
`define START_BIT 1'b0
`define STOP_BIT  1'b1

`define CLK_EDGE posedge
//`define CLK_EDGE negedge

module uart #(
  parameter CLK_FREQ = 48_000_000,      // clock frequency (Hz)
  parameter BIT_FREQ = 115_200          // baud rate (bits per second)
) (
  input            clk,                 // input clock
  input            wr,                  // write signal
  input [7:0]      d_out,               // character to transmit
  input            rx,                  // receive data
  output reg [7:0] d_in,                // character received
  output           ready,               // receive ready
  output           busy,                // transmit busy
  output           tx                   // transmit data
);

  // transmit baud-rate generator
  localparam TX_CNT = CLK_FREQ / BIT_FREQ;
  localparam TX_N = $clog2(TX_CNT);
  reg [TX_N-1:0] tx_cnt = TX_CNT - 1;

  // transmitter state-machine
  reg [8:0] tx_shift;  // transmit shift-register
  localparam TX_IDLE = 4'b1111;
  reg [3:0] tx_state = TX_IDLE;  // state-machine enumeration
  always @(`CLK_EDGE clk)
    case (tx_state)
      TX_IDLE :  // transmitter idle
        if (wr)  // on "write"
          begin
            tx_shift <= { d_out, `START_BIT };  // load shift register
            tx_cnt <= TX_CNT - 1;   // reset counter
            tx_state <= 0;
          end
      default :  // transmit data
        if (tx_cnt)
          tx_cnt <= tx_cnt - 1'b1;
        else
          begin
            tx_shift <= { `STOP_BIT, tx_shift[8:1] };
            tx_cnt <= TX_CNT - 1;   // reset counter
            tx_state <= (tx_state == 9) ? TX_IDLE : tx_state + 1'b1;
          end
    endcase
  assign tx = (tx_state == TX_IDLE) ? `IDLE_BIT : tx_shift[0];
  assign busy = (tx_state != TX_IDLE);

  // receive baud-rate generator
  localparam RX_CNT = CLK_FREQ / BIT_FREQ;
  localparam RX_N = $clog2(RX_CNT);
  reg [RX_N-1:0] rx_cnt = RX_CNT >> 1;

  // register async rx
  reg [1:0] rx_shift;  // receive shift-register
  always @(`CLK_EDGE clk)
    rx_shift <= { rx_shift[0], rx };

  // receiver state-machine
  reg [3:0] rx_state = RX_IDLE;
  localparam RX_IDLE = 4'b1111;
  always @(`CLK_EDGE clk)
    case (rx_state)
      RX_IDLE :  // receiver idle
        if (rx_shift == 2'b00)  // start edge
          begin
            rx_cnt <= (RX_CNT >> 1) - 1;  // count to midpoint
            rx_state = 0;
          end
      0 :  // start bit
        if (rx_cnt)
          rx_cnt <= rx_cnt - 1'b1;
        else
          begin
            d_in <= 8'h00;  // clear receive data
            rx_cnt <= RX_CNT - 1;  // reset counter
            rx_state <= (rx_shift == 2'b00) ? 1 : 9;
          end
      default :  // receive data
        if (rx_cnt)
          rx_cnt <= rx_cnt - 1'b1;
        else
          begin
            d_in <= { rx_shift[1], d_in[7:1] };
            rx_cnt <= RX_CNT - 1;  // reset counter
            rx_state <= rx_state + 1'b1;
          end
      9 :  // stop bit
        if (rx_cnt)
          rx_cnt <= rx_cnt - 1'b1;
        else
          begin
            rx_cnt <= (RX_CNT >> 1) - 1;  // count to midpoint
            rx_state <= (rx_shift == 2'b11) ? 10 : 9;
          end
      10 :  // ready (for one cycle)
        rx_state <= RX_IDLE;
    endcase
  assign ready = (rx_state == 10);

endmodule
```

```verilog
// uart.v
//
// serial UART (8N1)
//

`define IDLE_BIT  1'b1
`define START_BIT 1'b0
`define STOP_BIT  1'b1

`define CLK_EDGE posedge
//`define CLK_EDGE negedge

module uart #(
  parameter CLK_FREQ = 48_000_000,      // clock frequency (Hz)
  parameter BIT_FREQ = 115_200          // baud rate (bits per second)
) (
  input            clk,                 // input clock
  input            wr,                  // write signal
  input      [7:0] d_out,               // character to transmit
  input            rx,                  // receive data
  output reg [7:0] d_in,                // character received
  output           ready,               // receive ready
  output           busy,                // transmit busy
  output           tx                   // transmit data
);

  // transmit baud-rate generator
  localparam TX_CNT = CLK_FREQ / BIT_FREQ;
  localparam TX_N = $clog2(TX_CNT);
  reg [TX_N-1:0] tx_cnt;

  // transmitter state-machine
  reg [8:0] tx_shift;  // transmit shift-register
  localparam TX_IDLE = 4'b1111;
  reg [3:0] tx_state = TX_IDLE;  // state-machine enumeration
  always @(`CLK_EDGE clk)
    if (tx_state == TX_IDLE)  // transmitter idle
      begin
        if (wr)  // on "write"
          begin
            tx_shift <= { d_out, `START_BIT };  // load shift register
            tx_cnt <= TX_CNT - 1;   // reset counter
            tx_state <= 0;
          end
      end
    else if (tx_cnt)  // waiting...
      tx_cnt <= tx_cnt - 1'b1;
    else  // transmit data
      begin
        tx_shift <= { `STOP_BIT, tx_shift[8:1] };
        tx_cnt <= TX_CNT - 1;   // reset counter
        tx_state <= (tx_state == 9) ? TX_IDLE : tx_state + 1'b1;
      end
  assign tx = (tx_state == TX_IDLE) ? `IDLE_BIT : tx_shift[0];
  assign busy = (tx_state != TX_IDLE);

  // receive baud-rate generator
  localparam RX_CNT = CLK_FREQ / BIT_FREQ;
  localparam RX_N = $clog2(RX_CNT);
  reg [RX_N-1:0] rx_cnt;

  // register async rx
  reg [1:0] rx_shift;  // receive shift-register
  always @(`CLK_EDGE clk)
    rx_shift <= { rx_shift[0], rx };

  // receiver state-machine
  reg [3:0] rx_state = RX_IDLE;
  localparam RX_IDLE = 4'b1111;
  always @(`CLK_EDGE clk)
    if (rx_state == RX_IDLE)  // idle... watch for (negedge rx)
      begin
        if (rx_shift == 2'b00)  // start edge
          begin
            rx_cnt <= (RX_CNT >> 1) - 1;  // count to midpoint
            rx_state = 0;
          end
      end
    else if (rx_state == 10)  // ready (for one cycle)
      begin
        rx_state <= RX_IDLE;
      end
    else if (rx_cnt)  // waiting...
      rx_cnt <= rx_cnt - 1'b1;
    else if (rx_state == 0)  // start bit
      begin
        d_in <= 8'h00;  // clear receive data
        rx_cnt <= RX_CNT - 1;  // reset counter
        rx_state <= (rx_shift == 2'b00) ? 1 : 9;
      end
    else if (rx_state == 9)  // stop bit
      begin
        rx_cnt <= (RX_CNT >> 1) - 1;  // count to midpoint
        rx_state <= (rx_shift == 2'b11) ? 10 : 9;
      end
    else  // receive data
      begin
        d_in <= { rx_shift[1], d_in[7:1] };
        rx_cnt <= RX_CNT - 1;  // reset counter
        rx_state <= rx_state + 1'b1;
      end
  assign ready = (rx_state == 10);

endmodule
```

```verilog
// uart_tb.v
//
// simulation test bench for uart.v/uart_8n1.v
//

`define SIM_RATE 24

module test_bench;

  // bit-clock frequency
//  parameter BAUD_RATE = 115_200;
  parameter BAUD_RATE = 2_000_000;  // 2Mhz bit-clock for simulation only

  // dump simulation signals
  initial
    begin
      $dumpfile("test_bench.vcd");
      $dumpvars(0, test_bench);
      #(`SIM_RATE * 3) DTR <= 1;  // set data-terminal-ready
      #(`SIM_RATE * 1) DTR <= 0;  // clear data-terminal-ready
      #(`SIM_RATE * 24) DTR <= 1;  // set data-terminal-ready
      #(`SIM_RATE * 22) DTR <= 0;  // clear data-terminal-ready
      #(`SIM_RATE * 4) DTR <= 1;  // set data-terminal-ready
      #(`SIM_RATE * 12) DTR <= 0;  // clear data-terminal-ready
      #(`SIM_RATE * 8) $finish;  // stop simulation
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate device-under-test
  reg DTR = 0;  // data terminal ready
  wire RX;  // receive data
  wire RDY;  // receive ready
  wire TX;  // transmit data
  wire BSY;  // transmit busy
  wire [7:0] DATA;  // received data
  uart #(
    .BIT_FREQ(BAUD_RATE)
  ) DUT (
    .clk(clk),
    .wr(DTR),
    .d_out("K"),
    .rx(RX),
    .d_in(DATA),
    .ready(RDY),
    .busy(BSY),
    .tx(TX)
  );

  // loopback TX -> RX
  reg loopback = 1;  // idle line
  always @(posedge clk)
    loopback <= TX;
  assign RX = loopback;

endmodule
```
