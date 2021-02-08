// pitch.v
//
// musical tone generator
//

`default_nettype none

`include "pitch.vh"

module tone_gen #(
  parameter CLK_FREQ = 48_000_000
) (
  input            clk,                 // input clock (@ CLK_FREQ)
  input      [3:0] pitch,               // pitch index
  input      [2:0] octave,              // octave index
  output           out                  // output signal (@ OUT_FREQ)
);

  // frequency table
  localparam N = 12;
  reg [N-1:0] freq_cnt [`Z:`C];  // count indexed by pitch
  initial
    begin
      freq_cnt[`Z] = 0;
      freq_cnt[`B] = (CLK_FREQ / 61.73541) - 1;
      freq_cnt[`Bb] = (CLK_FREQ / 58.27047) - 1;
      freq_cnt[`A] = (CLK_FREQ / 55.00000) - 1;
      freq_cnt[`Ab] = (CLK_FREQ / 51.91309) - 1;
      freq_cnt[`G] = (CLK_FREQ / 48.99943) - 1;
      freq_cnt[`Gb] = (CLK_FREQ / 46.24930) - 1;
      freq_cnt[`F] = (CLK_FREQ / 43.65353) - 1;
      freq_cnt[`E] = (CLK_FREQ / 41.20344) - 1;
      freq_cnt[`Eb] = (CLK_FREQ / 38.89087) - 1;
      freq_cnt[`D] = (CLK_FREQ / 36.70810) - 1;
      freq_cnt[`Db] = (CLK_FREQ / 34.64783) - 1;
      freq_cnt[`C] = (CLK_FREQ / 32.70320) - 1;
/*
      $display("freq_cnt[%d] = %d", `Z, freq_cnt[`Z]);
      $display("freq_cnt[%d] = %d", `B, freq_cnt[`B]);
      $display("freq_cnt[%d] = %d", `Bb, freq_cnt[`Bb]);
      $display("freq_cnt[%d] = %d", `A, freq_cnt[`A]);
      $display("freq_cnt[%d] = %d", `Ab, freq_cnt[`Ab]);
      $display("freq_cnt[%d] = %d", `G, freq_cnt[`G]);
      $display("freq_cnt[%d] = %d", `Gb, freq_cnt[`Gb]);
      $display("freq_cnt[%d] = %d", `F, freq_cnt[`F]);
      $display("freq_cnt[%d] = %d", `E, freq_cnt[`E]);
      $display("freq_cnt[%d] = %d", `Eb, freq_cnt[`Eb]);
      $display("freq_cnt[%d] = %d", `D, freq_cnt[`D]);
      $display("freq_cnt[%d] = %d", `Db, freq_cnt[`Db]);
      $display("freq_cnt[%d] = %d", `C, freq_cnt[`C]);
*/
    end

  reg state = 1'b0;  // output state
  reg [N-1:0] timer = 0;  // countdown timer

  always @(posedge clk)
    if (timer)  // count down to zero
      timer <= timer - 1'b1;
    else if (pitch)  // toggle output on zero
      begin
        state <= !state;
        timer <= (freq_cnt[pitch] >> octave);
      end
    else  // rest
      begin
        state <= 1'b0;  // force 0 on rest
        timer <= 0;
      end

  assign out = state;

endmodule
