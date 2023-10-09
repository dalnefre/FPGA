/*

Test Bench for uart.v

*/

`default_nettype none

`include "uart.v"

`timescale 1us/10ns

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("uart.vcd");
      $dumpvars(0, test_bench);
      #1200;
      $finish;
    end

  // generate chip clock (500KHz simulation time)
  reg clk = 0;
  always
    #1 clk = !clk;

  parameter CLK_FREQ = 500_000;         // clock frequency (Hz)
  parameter BAUD_RATE = 115_200;        // baud rate (bits per second)

  wire led_r;
  wire led_g;
  wire led_b;

  // connect leds
  assign led_r = !uart_rx;  // FIXME: may need to "stretch" this signal
  assign led_g = !uart_tx;  // FIXME: may need to "stretch" this signal

  // instantiate integrated UART
  wire uart_rx;                         // serial receive line (RX)
  wire uart_tx;                         // serial transmit line (TX)
  uart #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
  ) UART (
    .i_clk(clk),
    .i_rx(uart_rx),
    .o_tx(uart_tx)
  );

  // baud counter to stretch simulated input
  localparam BAUD_CLKS = CLK_FREQ / BAUD_RATE;
  localparam CNT_BITS = $clog2(BAUD_CLKS);
  reg [CNT_BITS-1:0] baud_cnt;
  initial baud_cnt = BAUD_CLKS - 1;
  always @(posedge clk)
    if (baud_cnt > 0)
      baud_cnt <= baud_cnt - 1'b1;
    else
      baud_cnt <= BAUD_CLKS - 1;

  // produce test signal
  /*
    _____     _______     ___         ___     _________
         \___/       \___/   \_______/   \___/         
    IDLE | + | 1 | 1 | 0 | 1 | 0 | 0 | 1 | 0 | - | IDLE
         START                                STOP
  */
  reg [11:0] signal;
  initial signal = 12'b101101001011;  // ASCII "K"
  reg [3:0] sample;
  initial sample = 0;  // signal sample counter
  always @(posedge clk)
    if (baud_cnt == 0)
      begin
        if (sample == 0)
          sample <= 11;
        else
          sample <= sample - 1'b1;
      end
  assign uart_rx = signal[sample];

endmodule
