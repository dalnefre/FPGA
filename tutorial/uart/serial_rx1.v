// serial_rx1.v
//
// serial receiver (no edge re-sync)
//

`include "uart.vh"

module serial_rx #(
  parameter CLK_FREQ = 48_000_000,      // clock frequency (Hz)
  parameter BIT_FREQ = 115_200          // baud rate (bits per second)
) (
  input            clk,                 // system clock
  input            rx,                  // received data (async)
  output reg       break = 1'b0,        // line break condition
  output reg       ready = 1'b0,        // character data ready
  output reg [7:0] data                 // character received
);

  // receive baud-rate timer
  localparam BIT_PERIOD = CLK_FREQ / BIT_FREQ;
  localparam FULL_BIT_TIME = BIT_PERIOD - 1;
  localparam HALF_BIT_TIME = FULL_BIT_TIME >> 1;
  localparam N_TIMER = $clog2(BIT_PERIOD);
  reg [N_TIMER-1:0] timer = 0;

  initial
    begin
      $display("BIT_PERIOD = %d", BIT_PERIOD);
      $display("FULL_BIT_TIME = %d", FULL_BIT_TIME);
      $display("HALF_BIT_TIME = %d", HALF_BIT_TIME);
    end

  // register async rx
  reg [2:0] sync = { 3 { `IDLE_BIT } };  // receive sync-register
  always @(posedge clk)
    sync <= { sync[1:0], rx };
  wire in = sync[2];  // synchronized input

  // receiver state-machine
  reg [3:0] bits = 4'd0;  // received bit count
  always @(posedge clk)
    if (timer)  // count down delay
      timer <= timer - 1'b1;
    else if (bits)  // capture data
      begin
        if ((bits == 4'd1) && (in != `START_BIT))  // false start
          bits <= 4'd0;
        else if (bits == 4'd10)  // stop
          begin
            if (in == `STOP_BIT)
              begin
                break <= 1'b0;  // no error
                ready <= 1'b1;  // data ready
              end
            else
              begin
                break <= 1'b1;  // framing error
                timer <= HALF_BIT_TIME;
              end
            bits <= 4'd0;  // reset bit count
          end
        else  // data bit
          begin
            data <= { in, data[7:1] };
            timer <= FULL_BIT_TIME;
            bits <= bits + 1'b1;
          end
      end
    else if (in == `START_BIT)  // possible start
      begin
        timer <= HALF_BIT_TIME;
        bits <= 4'd1;
      end

  always @(posedge clk)
    if (ready)  // reset ready after 1 clock-cycle
      ready <= 1'b0;

endmodule