// pitch_tb.v
//
// simulation test bench for pitch.v
//

`default_nettype none

`include "pitch.vh"

module test_bench;

  //localparam CLK_FREQ = 48_000_000;
  //localparam CLK_FREQ = 16_000_000;
  localparam CLK_FREQ = 46_875;
  //localparam NOTE_DUR = CLK_FREQ;  // 120 bpm
  localparam NOTE_DUR = CLK_FREQ / 3;  // 360 bpm

  localparam WHL_NOTE = NOTE_DUR >> 0;
  localparam HLF_NOTE = NOTE_DUR >> 1;
  localparam QTR_NOTE = NOTE_DUR >> 2;
  localparam ETH_NOTE = NOTE_DUR >> 3;
  localparam SXT_NOTE = NOTE_DUR >> 4;

  localparam NOTE_GAP = NOTE_DUR >> 6;

  // dump simulation signals
  initial
    begin
      $dumpfile("pitch.vcd");
      $dumpvars(0, test_bench);
      #(NOTE_DUR * 3);  // run for 1.5 measures (4/4 time)
      $finish;  // stop simulation
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate device-under-test
  reg [3:0] pitch = `Z;
  reg [2:0] octave = 0;
  wire out;
  tone_gen #(
    .CLK_FREQ(CLK_FREQ)
  ) DUT (
    .clk(clk),
    .pitch(pitch),
    .octave(octave),
    .out(out)
  );

  // instruction type encoding
  localparam OP_PITCH = 1'b0;
  localparam OP_DELAY = 1'b1;

  //  Close Encounters: D4 E4 C4 C3 G3
  reg [7:0] tune [0:15];  // 16x8-bit instructions
  initial
    begin
      $readmemh("pitch.hex", tune);
/*
      tune[4'h0] = { OP_PITCH, 3'd4, `D };
      tune[4'h1] = { OP_DELAY, 3'd0, 4'd2 };
      tune[4'h2] = { OP_PITCH, 3'd4, `E };
      tune[4'h3] = { OP_DELAY, 3'd0, 4'd3 };
      tune[4'h4] = { OP_PITCH, 3'd4, `C };
      tune[4'h5] = { OP_DELAY, 3'd0, 4'd3 };
      tune[4'h6] = { OP_PITCH, 3'd3, `C };
      tune[4'h7] = { OP_DELAY, 3'd0, 4'd2 };
      tune[4'h8] = { OP_PITCH, 3'd3, `G };
      tune[4'h9] = { OP_DELAY, 3'd0, 4'd2 };
      tune[4'hA] = { OP_PITCH, 3'd0, `Z };
      tune[4'hB] = { OP_DELAY, 3'd0, 4'd2 };
      tune[4'hC] = { OP_PITCH, 3'd0, `Z };
      tune[4'hD] = { OP_DELAY, 3'd0, 4'd2 };
      tune[4'hE] = { OP_PITCH, 3'd0, `Z };
      tune[4'hF] = { OP_DELAY, 3'd0, 4'd2 };
*/
//      $writememh("pitch2.hex", tune);
    end

  // sequencer state-machine
  localparam SEQ_EXEC = 2'b00;
  localparam SEQ_TONE = 2'b01;
  localparam SEQ_WAIT = 2'b10;
  localparam SEQ_HALT = 2'b11;
  reg [1:0] seq_state = SEQ_EXEC;
  reg [3:0] seq_index = 0;  // index into tune[] program
  reg [26:0] seq_cnt = 0;  // delay timer
  wire [7:0] ins = tune[seq_index];  // current instruction
  always @(posedge clk)
    if (seq_cnt)  // count down to zero
      seq_cnt <= seq_cnt - 1'b1;
    else  // take action on zero
      case (seq_state)
        SEQ_EXEC :  // execute instruction
          begin
            if (ins[7] == OP_PITCH)
              begin
                pitch <= ins[3:0];
                octave <= ins[6:4];
              end
            else if (ins[7] == OP_DELAY)
              begin
                seq_cnt <= (WHL_NOTE >> ins[3:0]) - NOTE_GAP;
                seq_state <= SEQ_TONE;
              end
            seq_index <= seq_index + 1;  // move to next instruction
          end
        SEQ_TONE :  // play note for duration
          begin
            pitch <= `Z;
            octave <= 0;
            seq_cnt <= NOTE_GAP;
            seq_state <= SEQ_WAIT;
          end
        SEQ_WAIT :  // wait between notes
          seq_state <= SEQ_EXEC;
        default :  // halt
          seq_state <= SEQ_HALT;
      endcase

endmodule