// serial_rx.v
//
// serial receiver
//

`include "uart.vh"

// state-machine states
`define START 4'b0000  // 4'h0
`define ZERO  4'b0100  // 4'h4
`define POS   4'b0101  // 4'h5
`define ONE   4'b0111  // 4'h7
`define NEG   4'b0110  // 4'h6
`define STOP  4'b0001  // 4'h1
`define READY 4'b1001  // 4'h9
`define IDLE  4'b1111  // 4'hF
`define BREAK 4'b1110  // 4'hE
`define HALT  4'b1010  // 4'hA

module serial_rx #(
  parameter CLK_FREQ = 48_000_000,      // clock frequency (Hz)
  parameter BIT_FREQ = 115_200          // baud rate (bits per second)
) (
  input            clk,                 // system clock
  input            rx,                  // received data (async)
  output           break,               // line break condition
  output           ready,               // character data ready
  output     [7:0] data                 // character received
);

  // receive baud-rate timer
  localparam BIT_TIME = CLK_FREQ / BIT_FREQ;
  localparam FULL_BIT_TIME = BIT_TIME - 1;
  localparam HALF_BIT_TIME = (BIT_TIME >> 1) - 1;
  localparam N_TIMER = $clog2(BIT_TIME);
  reg [N_TIMER-1:0] timer = FULL_BIT_TIME;

  initial
    begin
      $display("BIT_TIME = %d", BIT_TIME);
      $display("FULL_BIT_TIME = %d", FULL_BIT_TIME);
      $display("HALF_BIT_TIME = %d", HALF_BIT_TIME);
    end

  // register async rx
  reg [2:0] sync;  // receive sync-register
  always @(posedge clk)
    sync <= { sync[1:0], rx };
  wire in = sync[2];  // synchronized input

  // receiver state-machine
  reg [9:0] shift = { 10 { `IDLE } };
  reg [3:0] cnt = 0;
  reg [3:0] state = `IDLE;
  always @(posedge clk)
    case (state)
      `IDLE :
        if (in == 0)
          begin
            timer <= 0;
            state <= `START;
          end
      `START :
        if (in != 0)  // glitch
          state <= `IDLE;
        else if (timer < HALF_BIT_TIME)
          timer <= timer + 1'b1;
        else
          begin
            cnt <= 0;
            timer <= 0;
            state <= `ZERO;
          end
      `ZERO :
        if (in != 0)  // positive edge
          begin
            timer <= 0;  // re-sync on edge
            state <= `POS;
          end
        else if (timer < FULL_BIT_TIME)
          timer <= timer + 1'b1;
        else  // next bit
          begin
            shift <= { 1'b0, shift[9:1] };  // shift in MSB
            cnt <= cnt + 1'b1;
            timer <= 0;
            state <= (cnt < 8) ? `ZERO : `BREAK;
          end
      `POS :
        if (in == 0)  // glitch
          begin
            timer <= timer + HALF_BIT_TIME;  // restore timer
            state <= `ZERO;
          end
        else if (timer < HALF_BIT_TIME)
          timer <= timer + 1'b1;
        else  // next bit
          begin
            shift <= { 1'b0, shift[9:1] };  // shift in MSB
            cnt <= cnt + 1'b1;
            timer <= 0;
            state <= (cnt < 8) ? `ONE : `STOP;
          end
      `ONE :
        if (in == 0)  // negative edge
          begin
            timer <= 0;  // re-sync on edge
            state <= `NEG;
          end
        else if (timer < FULL_BIT_TIME)
          timer <= timer + 1'b1;
        else  // next bit
          begin
            shift <= { 1'b1, shift[9:1] };  // shift in MSB
            cnt <= cnt + 1'b1;
            timer <= 0;
            state <= (cnt < 8) ? `ONE : `STOP;
          end
      `NEG :
        if (in != 0)  // glitch
          begin
            timer <= timer + HALF_BIT_TIME;  // restore timer
            state <= `ONE;
          end
        else if (timer < HALF_BIT_TIME)
          timer <= timer + 1'b1;
        else  // next bit
          begin
            shift <= { 1'b1, shift[9:1] };  // shift in MSB
            cnt <= cnt + 1'b1;
            timer <= 0;
            state <= (cnt < 8) ? `ZERO : `BREAK;
          end
      `STOP :
        state <= `IDLE;  // only one clock-cycle in STOP
      `BREAK :
        if (in == 0)
          timer <= 0;  // reset counter
        else if (timer < HALF_BIT_TIME)
          timer <= timer + 1'b1;
        else  // come out of break/reset
          state <= `IDLE;
      default :  // unexpected state
        state <= `HALT;
    endcase

  assign data = shift[8:1];
  assign ready = (state == `STOP);

  wire monitor = state[0];  // FIXME -- for debugging only.

/*
  // receiver state-machine
  reg [3:0] state = RX_IDLE;
  always @(posedge clk)
    case (state)
      RX_IDLE :  // receiver idle
        if (shift == 2'b00)  // start edge
          begin
            timer <= (BIT_TIME >> 1) - 1;  // count to midpoint
            state = 0;
          end
      0 :  // start bit
        if (timer)
          timer <= timer - 1'b1;
        else
          begin
            d_in <= 8'h00;  // clear receive data
            timer <= BIT_TIME - 1;  // reset counter
            state <= (shift == 2'b00) ? 1 : 9;
          end
      default :  // receive data
        if (timer)
          timer <= timer - 1'b1;
        else
          begin
            d_in <= { shift[1], d_in[7:1] };
            timer <= BIT_TIME - 1;  // reset counter
            state <= state + 1'b1;
          end
      9 :  // stop bit
        if (timer)
          timer <= timer - 1'b1;
        else
          begin
            timer <= (BIT_TIME >> 1) - 1;  // count to midpoint
            state <= (shift == 2'b11) ? 10 : 9;
          end
      10 :  // ready (for one cycle)
        state <= RX_IDLE;
    endcase

  // data-ready signal
  assign ready = (state == 10);
*/

endmodule