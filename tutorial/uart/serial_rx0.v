// serial_rx0.v
//
// serial receiver (bare-bones)
//

`default_nettype none

`include "uart.vh"

module serial_rx #(
  parameter CLK_FREQ = 48_000_000,      // clock frequency (Hz)
  parameter BIT_FREQ = 115_200          // baud rate (bits per second)
) (
  input            clk,                 // system clock
  input            rx,                  // received data (async)
  output reg       break = 1'b0,        // line break condition (always false)
  output reg       ready = 1'b0,        // character data ready
  output reg [7:0] data                 // character received
);

  // receive baud-rate timer
  localparam BIT_PERIOD = CLK_FREQ / BIT_FREQ;
  localparam FULL_BIT_TIME = BIT_PERIOD - 1;
//  localparam HALF_BIT_TIME = BIT_PERIOD / 2;
  localparam HALF_BIT_TIME = FULL_BIT_TIME >> 1;
  localparam START_BIT_TIME = FULL_BIT_TIME + HALF_BIT_TIME;
  localparam N_TIMER = $clog2(BIT_PERIOD);
  reg [N_TIMER-1:0] timer;

  initial
    begin
      $display("BIT_PERIOD = %d", BIT_PERIOD);
      $display("FULL_BIT_TIME = %d", FULL_BIT_TIME);
      $display("HALF_BIT_TIME = %d", HALF_BIT_TIME);
    end

  // synchronize incoming bit
  reg rx_rr, rx_r;
  initial
    { rx_rr, rx_r } = -1;  // idle = 1
  always @(posedge clk)
    { rx_rr, rx_r } <= { rx_r, rx };

  // receiver state-machine
  reg [3:0] state;
  localparam IDLE = 0;
  localparam START = 1;
  localparam STOP = 9;
  initial
    begin
      timer = 0;
      state <= IDLE;
      ready = 1'b0;
    end
  always @(posedge clk)
    if (state == IDLE)
      begin
        timer <= 0;
        state <= IDLE;
        if (!rx_rr)
          begin
            timer <= START_BIT_TIME; // CLOCKS_PER_BAUD-1 + CLOCKS_PER_BAUD/2;
            state <= START;
          end
      end
    else if (timer == 0)
      begin
        timer <= FULL_BIT_TIME;
        state <= state + 1'b1;
        if (state >= STOP)
          state <= IDLE;
        if (state == STOP)
          timer <= 0;
      end
    else
      timer <= timer - 1'b1;
  always @(posedge clk)
    if ((timer == 0) && (state != STOP))
      data <= { rx_rr, data[7:1] };
  always @(posedge clk)
    ready <= ((timer == 0) && (state == STOP));

endmodule