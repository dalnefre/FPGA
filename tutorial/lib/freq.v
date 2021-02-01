// freq.v
//
// frequency generator (w/ variable duty-cycle)
//

`default_nettype none

module freq #(
  parameter              INIT = 0,        // initial signal level
  parameter              N_CNT = 8        // number of count bits
) (
  input                  clk,             // input clock
  input      [N_CNT-1:0] lo,              // number of clock-cycles low
  input      [N_CNT-1:0] hi,              // number of clock-cycles high
  output reg             out              // registered output signal
);

  reg [N_CNT-1:0] cnt;  // countdown timer

  initial
    begin
      out = INIT;
      cnt = 0;
    end

  always @(posedge clk)
    if (cnt)  // count down to zero
      cnt <= cnt - 1;
    else if (out)  // high phase
      begin
        if (lo)
          begin
            cnt <= lo - 1;
            out <= 1'b0;
          end
      end
    else // low phase
      begin
        if (hi)
          begin
            cnt <= hi - 1;
            out <= 1'b1;
          end
      end

endmodule
