// usb_1.v
//
// USB full-speed device (tx)
//

`include "usb.vh"

module usb_tx (
  input            clk,                 // 48MHz system clock
  input            valid,               // data valid
  input      [7:0] data,                // data to send
  output reg       rd = 0,              // read data
  output reg       en = 0,              // transmit enable
  inout            usb_p,               // USB D+ signal
  inout            usb_n                // USB D- signal
);

  localparam BIT_PERIOD = 4;  // (48MHz / 12Mbps) = 4 clocks per bit
  localparam FULL_BIT_TIME = BIT_PERIOD - 1;
  localparam N_TIMER = $clog2(BIT_PERIOD);

  // transmitter state-machine
  reg eop = 0;  // end-of-packet flag
  reg [1:0] tick = 0;  // bit clock timer
  reg [2:0] bits = 0;  // number of bits to transmit
  reg [2:0] ones = 0;  // number of consecutive ones
  reg [7:0] shift;  // transmit shift-register
  reg [1:0] D = `LINE_J;  // differential signal pair
  always @(posedge clk)
    begin
      rd <= 0;  // clear read ack
      if (tick)  // delay
        tick <= tick - 1'b1;  // count down bit-time
      else if (!eop && bits)  // more bits to transmit
        begin
          tick <= FULL_BIT_TIME;
          if (shift[0])
            begin
              if (ones < 6)
                begin
                  ones <= ones + 1'b1;
                  bits <= bits - 1'b1;  // count down bits
                  shift <= { 1'b0, shift[6:1] };
                end
              else  // stuff zero
                begin
                  D <= (D == `LINE_J) ? `LINE_K : `LINE_J;
                  ones <= 0;
                end
            end
          else
            begin
              D <= (D == `LINE_J) ? `LINE_K : `LINE_J;
              ones <= 0;
              bits <= bits - 1'b1;  // count down bits
              shift <= { 1'b0, shift[6:1] };
            end
        end
      else if (!eop && valid)  // more data to load
        begin
          rd <= 1;  // set read ack
          en <= 1;  // enable transmitter
          tick <= FULL_BIT_TIME;
          if (data[0])
            begin
              bits <= 7;
              if (ones < 6)
                begin
                  ones <= ones + 1'b1;
                  shift <= { 1'b0, data[7:1] };
                end
              else  // stuff zero
                begin
                  D <= (D == `LINE_J) ? `LINE_K : `LINE_J;
                  ones <= 0;
                  shift <= data;
                end
            end
          else
            begin
              bits <= 7;
              D <= (D == `LINE_J) ? `LINE_K : `LINE_J;
              ones <= 0;
              shift <= { 1'b0, data[7:1] };
            end
        end
      else if (en)  // end of packet
        if (bits < 3)
          begin
            D <= (bits < 2) ? `LINE_Z : `LINE_J;
            eop <= 1;
            tick <= FULL_BIT_TIME;
            bits <= bits + 1'b1;  // count up end bits
          end
        else
          begin
            en <= 0;  // disable transmitter
            eop <= 0;
            tick <= 0;
            bits <= 0;
            ones <= 0;
          end
    end

  assign { usb_p, usb_n } = en ? D : 2'bZ;  // transmit differential signal

endmodule