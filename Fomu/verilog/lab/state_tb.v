/*

Test Bench for state.v (state-machine template)

*/

`timescale 100ns/1ns

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("state.vcd");
      $dumpvars(0, test_bench);
      #1200;
      $finish;
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // free-running counter
  reg [3:0] count;
  initial count = 0;
  always @(posedge clk)
    count <= count + 1'b1;

  // countdown timer
  reg [15:0] timer;
  initial timer = 0;
  wire t_zero;
  assign t_zero = (timer == 0);  // timer stopped

  // enumerated values for state
  localparam START  = 4'h0;
  localparam WAIT   = 4'h7;
  localparam STOP   = 4'hF;

  // state-machine (w/ timer delay)
  reg [3:0] state = START;  // initial state
  always @(posedge clk)
    if (!t_zero)
      timer <= timer - 1'b1;
    else
      case (state)
        START:
          if (count[3])
            begin
              timer <= 5;
              state <= WAIT;
            end
        WAIT:
          begin
            timer <= 3;
            state <= STOP;
          end
        STOP:
          timer <= 16'd48_000 - 1;  // 1ms @ 48Hz
        default:
          state <= STOP;
      endcase

endmodule
