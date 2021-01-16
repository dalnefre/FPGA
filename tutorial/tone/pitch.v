// pitch.v
//
// musical tone generator
//

`include "pitch.vh"

module tone_gen #(
  parameter CLK_FREQ = 48_000_000
) (
  input       clk,                      // input clock (@ CLK_FREQ)
  input [3:0] pitch,                    // pitch index
  input [2:0] octave,                   // octave index
  output reg  tone = 0                  // output tone (@ OUT_FREQ)
);

  // frequency table
  reg [21:0] freq_cnt [`Z:`C];  // count indexed by pitch
  initial
    begin
      freq_cnt[`Z] = 0;
      $display("freq_cnt[%d] = %d", `Z, freq_cnt[`Z]);
      freq_cnt[`B] = CLK_FREQ / 30.86771;
      $display("freq_cnt[%d] = %d", `B, freq_cnt[`B]);
      freq_cnt[`Bb] = CLK_FREQ / 29.13524;
      $display("freq_cnt[%d] = %d", `Bb, freq_cnt[`Bb]);
      freq_cnt[`A] = CLK_FREQ / 27.50000;
      $display("freq_cnt[%d] = %d", `A, freq_cnt[`A]);
      freq_cnt[`Ab] = CLK_FREQ / 25.95654;
      $display("freq_cnt[%d] = %d", `Ab, freq_cnt[`Ab]);
      freq_cnt[`G] = CLK_FREQ / 24.49971;
      $display("freq_cnt[%d] = %d", `G, freq_cnt[`G]);
      freq_cnt[`Gb] = CLK_FREQ / 23.12465;
      $display("freq_cnt[%d] = %d", `Gb, freq_cnt[`Gb]);
      freq_cnt[`F] = CLK_FREQ / 21.82676;
      $display("freq_cnt[%d] = %d", `F, freq_cnt[`F]);
      freq_cnt[`E] = CLK_FREQ / 20.60172;
      $display("freq_cnt[%d] = %d", `E, freq_cnt[`E]);
      freq_cnt[`Eb] = CLK_FREQ / 19.44544;
      $display("freq_cnt[%d] = %d", `Eb, freq_cnt[`Eb]);
      freq_cnt[`D] = CLK_FREQ / 18.35405;
      $display("freq_cnt[%d] = %d", `D, freq_cnt[`D]);
      freq_cnt[`Db] = CLK_FREQ / 17.32391;
      $display("freq_cnt[%d] = %d", `Db, freq_cnt[`Db]);
      freq_cnt[`C] = CLK_FREQ / 16.35160;
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
          cnt <= (freq_cnt[pitch] >> (octave + 1)) - 1;
        end
      else  // rest
        begin
          tone <= 0;  // force 0 on rest
          cnt <= 0;
        end

endmodule