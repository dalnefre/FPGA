// serial_rx.v
//
// serial receiver
//

`include "uart.vh"

// state-machine states
`define START 3'b100  // 4'h4
`define ZERO  3'b000  // 4'h0
`define POS   4'b001  // 4'h1
`define ONE   4'b011  // 4'h3
`define NEG   4'b010  // 4'h2
`define STOP  4'b101  // 4'h5
`define IDLE  4'b111  // 4'h7
`define BREAK 4'b110  // 4'h6

module serial_rx #(
  parameter CLK_FREQ = 48_000_000,      // clock frequency (Hz)
  parameter BIT_FREQ = 115_200          // baud rate (bits per second)
) (
  input            clk,                 // system clock
  input            rx,                  // received data (async)
  output           break,               // line break condition
  output           ready,               // character data ready
  output reg [7:0] data                 // character received
);

  // receive baud-rate timer
  localparam BIT_PERIOD = CLK_FREQ / BIT_FREQ;
  localparam FULL_BIT_TIME = BIT_PERIOD - 1;
//  localparam HALF_BIT_TIME = (BIT_PERIOD >> 1) - 1;
  localparam HALF_BIT_TIME = FULL_BIT_TIME >> 1;
  localparam N_TIMER = $clog2(BIT_PERIOD);
  reg [N_TIMER-1:0] timer = FULL_BIT_TIME;

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
  reg [3:0] cnt = 0;
  reg [2:0] state = `IDLE;
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
            data <= 0;
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
            data <= { 1'b0, data[7:1] };  // shift in MSB 0
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
            data <= { 1'b0, data[7:1] };  // shift in MSB 0
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
            data <= { 1'b1, data[7:1] };  // shift in MSB 1
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
            data <= { 1'b1, data[7:1] };  // shift in MSB 1
            cnt <= cnt + 1'b1;
            timer <= 0;
            state <= (cnt < 8) ? `ZERO : `BREAK;
          end
      `STOP :
        begin
          state <= `IDLE;  // only one clock-cycle in `STOP
//          $display("received = 16#%x", data);
        end
      `BREAK :
        if (in == 0)
          timer <= 0;  // reset counter
        else if (timer < HALF_BIT_TIME)
          timer <= timer + 1'b1;
        else  // come out of break/reset
          state <= `IDLE;
      default :  // unexpected state
        state <= `BREAK;
    endcase

  assign ready = (state == `STOP);
  assign break = (state == `BREAK);

  wire monitor = state[0];  // LSB of state should track `in`

endmodule
