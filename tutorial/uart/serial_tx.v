// serial_tx.v
//
// serial transmitter
//

`include "uart.vh"

module serial_tx #(
  parameter CLK_FREQ = 48_000_000,      // clock frequency (Hz)
  parameter BIT_FREQ = 115_200          // baud rate (bits per second)
) (
  input            clk,                 // system clock
  input            wr,                  // write data
  input      [7:0] data,                // octet to transmit
  output           busy,                // transmit busy
  output           tx                   // transmit data
);

  // transmit baud-rate timer
  localparam BIT_PERIOD = CLK_FREQ / BIT_FREQ;
  localparam FULL_BIT_TIME = BIT_PERIOD - 1;
  localparam N_TIMER = $clog2(BIT_PERIOD);
  reg [N_TIMER-1:0] timer = FULL_BIT_TIME;

  reg [9:0] shift = { 10 { `IDLE_BIT } };  // transmit shift-register
  reg [3:0] cnt = 0;  // bit counter

  always @(posedge sys_clk)
    if (cnt == 0)  // transmitter idle
      if (wr)
        begin
          shift <= { `STOP_BIT, data, `START_BIT };  // load data into shift-register
          cnt <= 1;  // start counting bits
        end
      else
        shift = { 10 { `IDLE_BIT } };  // reset shift-register
    else if (timer)
      timer <= timer - 1'b1;
    else
      begin
        timer <= FULL_BIT_TIME;
        shift <= { `IDLE_BIT, shift[9:1] };  // shift to next output bit
        cnt <= (cnt > 10) ? 0 : cnt + 1'b1;  // increment (or reset) bit counter
      end

  assign busy = !cnt;  // transmitter is busy when counting
  assign tx = shift[0];  // transmit LSB of shift register

endmodule