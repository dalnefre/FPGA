// serial_tx.v
//
// serial transmitter
//

`include "uart.vh"

module serial_tx (
  input       sys_clk,                  // system clock
  input       bit_clk,                  // bit clock (at baud-rate frequency)
  input [7:0] data,                     // character to transmit
  output      tx                        // transmit data
);

  reg [9:0] shift = { 10 { `IDLE_BIT } };  // transmit shift-register
  reg [3:0] index = 0;  // bit count-down index

  always @(posedge sys_clk)
    if (bit_clk)
      begin
        if (index)
          begin
            shift <= { `IDLE_BIT, shift[9:1] };  // shift to next bit
            index <= index - 1'b1;  // decrement bit counter
          end
        else
          begin
            shift <= { `STOP_BIT, data, `START_BIT };  // load data into shift-register
            index <= 9;  // set full bit count
          end
      end

  assign tx = shift[0];

endmodule