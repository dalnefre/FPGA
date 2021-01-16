// usb_0.v
//
// USB full-speed device (rx)
//

`include "usb.vh"

module usb_rx (
  input            clk,                 // 48MHz system clock
  inout            usb_p,               // USB D+ signal
  inout            usb_n,               // USB D- signal
  output reg       ready = 0,           // data ready
  output reg       eop = 0,             // end-of-packet
  output reg [7:0] data = 8'hFF         // data received
);

  // register async rx
  reg [2:0] dp = 0;  // D+ sync-register
  reg [2:0] dn = 0;  // D- sync-register
  always @(posedge clk)
    begin
      dp <= { dp[1:0], usb_p };
      dn <= { dn[1:0], usb_n };
    end
  wire D_p = dp[2];  // synchronized D+
  wire D_n = dn[2];  // synchronized D-
  wire [1:0] D = { D_p, D_n };
  wire V = ((dp[2] == dp[1]) && (dn[2] == dn[1]));  // valid input agreement

  // state-machine states
  localparam RESET = 4'h0;
  localparam IDLE = 4'h1;
  localparam SYNC = 4'h2;
  localparam DATA = 4'h3;
  localparam END = 4'h4;
  localparam ERROR = 4'hF;

  // receiver state-machine
  reg [2:0] state = RESET;
  reg [1:0] phase = `LINE_J;
  reg [1:0] tick = 0;
  reg [2:0] bits = 0;
  reg [2:0] ones = 0;
  wire bit = (D == phase);
  always @(posedge clk)
    case (state)
      RESET :
        if (V && (D != `LINE_Z))
          state <= IDLE;
      IDLE :
        begin
          eop <= 0;
          if (V && (D == `LINE_K))
            begin
              phase <= `LINE_J;
              state <= SYNC;
              tick <= 0;
              bits <= 0;
              ones <= 0;
              data <= 8'hFF;
            end
          else if (V && (D == `LINE_Z))
            state <= RESET;
        end
      SYNC :
        begin
          if (!tick)
            begin
              if (V)
                begin
                  data <= { bit, data[7:1] };
                  phase <= D;
                  if (bits == 3'd7)
                    begin
                      state <= DATA;
                      ready <= 1;
                      ones <= 1;
                    end
                end
              else
                state <= ERROR;
              bits <= bits + 1'b1;
            end
          tick <= tick + 1'b1;
        end
      DATA :
        begin
          ready <= 0;
          if (!tick)
            begin
              if (!bits && (D == `LINE_Z))
                begin
                  state <= END;
                  bits <= bits + 1'b1;
                end
              else if (V)
                begin
                  if (ones < 6)
                    begin
                      data <= { bit, data[7:1] };
                      ones <= bit ? ones + 1'b1 : 0;
                      bits <= bits + 1'b1;
                    end
/*
                  else if (bit)
                    state <= ERROR;
*/
                  else  // ignore "stuffed" bit
                    ones <= 0;
                  phase <= D;
                  if (bits == 3'd7)
                    ready <= 1;
                end
              else
                state <= ERROR;
            end
          tick <= tick + 1'b1;
        end
      END :
        begin
          data <= 8'hFF;
          if (!tick)
            if ((bits == 3'd1) && (D != `LINE_Z))
              state <= ERROR;
            else if ((bits == 3'd2) && (D != `LINE_J))
              state <= ERROR;
            else if (bits != 3'd3)
              bits <= bits + 1'b1;
            else
              begin
                state <= IDLE;
                eop <= 1;
              end
          tick <= tick + 1'b1;
        end
      ERROR :
        if (V && (D == `LINE_Z))
          state <= RESET;
      default :  // unexpected state
        state <= ERROR;
    endcase

endmodule