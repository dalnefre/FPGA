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
  output reg       tone = 0             // output tone (@ OUT_FREQ)
);

  // frequency table
  reg [21:0] freq_cnt [`Z:`C];  // count indexed by pitch
  initial
    begin
      freq_cnt[`Z] = 0;
      freq_cnt[`B] = CLK_FREQ / 30.86771;
      freq_cnt[`Bb] = CLK_FREQ / 29.13524;
      freq_cnt[`A] = CLK_FREQ / 27.50000;
      freq_cnt[`Ab] = CLK_FREQ / 25.95654;
      freq_cnt[`G] = CLK_FREQ / 24.49971;
      freq_cnt[`Gb] = CLK_FREQ / 23.12465;
      freq_cnt[`F] = CLK_FREQ / 21.82676;
      freq_cnt[`E] = CLK_FREQ / 20.60172;
      freq_cnt[`Eb] = CLK_FREQ / 19.44544;
      freq_cnt[`D] = CLK_FREQ / 18.35405;
      freq_cnt[`Db] = CLK_FREQ / 17.32391;
      freq_cnt[`C] = CLK_FREQ / 16.35160;

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
    end

  reg [21:0] cnt = 0;  // count register

  always @(posedge clk)
    if (cnt)  // count down to zero
      cnt <= cnt - 1;
    else  // toggle output on zero
      if (pitch)
        begin
          tone <= !tone;
          cnt <= (freq_cnt[pitch] >> octave) - 1;
        end
      else  // rest
        begin
          tone <= 0;  // force 0 on rest
          cnt <= 0;
        end

endmodule
