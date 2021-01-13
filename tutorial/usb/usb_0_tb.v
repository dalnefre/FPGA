// usb_0_tb.v
//
// simulation test bench for usb_0.v
//

`include "usb.vh"

`define CLK_TICK (1)
`define CLK_PER (`CLK_TICK * 2)
`define CLK_FREQ (48)
`define BIT_FREQ (12)
`define BIT_CLKS (`CLK_FREQ / `BIT_FREQ)
`define BIT_TIME (`BIT_CLKS * `CLK_PER)

`define P_SKEW (0)
`define P_HI_TIME (`BIT_TIME)
`define P_LO_TIME (`BIT_TIME)
`define N_SKEW (0)
`define N_HI_TIME (`BIT_TIME)
`define N_LO_TIME (`BIT_TIME)
/*
`define P_SKEW (-1)
`define P_HI_TIME (`BIT_TIME - 1)
`define P_LO_TIME (`BIT_TIME + 1)
`define N_SKEW (0)
`define N_HI_TIME (`BIT_TIME - 1)
`define N_LO_TIME (`BIT_TIME + 1)
*/

/*
The following waveform represents transmission of a USB NAK packet.
   _____   _   _   _     ___       ___
D+      \_/ \_/ \_/ \___/   \_____/   \________
         _   _   _   ___     _____     _
D- _____/ \_/ \_/ \_/   \___/     \___/ \______

DIFF     K J K J K J K K J J K K K J J K Z Z J

NRZI     0 0 0 0 0 0 0 1 0 1 0 1 1 0 1 0 - - -
        |--clock sync---|--NAK packet---|-EOP-|
*/

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("usb_0.vcd");
      $dumpvars(0, test_bench);
      $display("`BIT_CLKS = %d", `BIT_CLKS);
      #(`BIT_CLKS * `CLK_PER * 24);
      $finish;
    end

/*
  // generate test signal
  initial
    begin
      // idle line
      usb_p = 1; usb_n = 0;
      #(`CLK_TICK * 12);

      // clock sync
      usb_p = 0; usb_n = 1;  // K
      #(`BIT_TIME);
      usb_p = 1; usb_n = 0;  // J
      #(`BIT_TIME);
      usb_p = 0; usb_n = 1;  // K
      #(`BIT_TIME);
      usb_p = 1; usb_n = 0;  // J
      #(`BIT_TIME);
      usb_p = 0; usb_n = 1;  // K
      #(`BIT_TIME);
      usb_p = 1; usb_n = 0;  // J
      #(`BIT_TIME);
      usb_p = 0; usb_n = 1;  // K
      #(`BIT_TIME);
      usb_p = 0; usb_n = 1;  // K
      #(`BIT_TIME);

      // NAK packet
      usb_p = 1; usb_n = 0;  // J
      #(`BIT_TIME);
      usb_p = 1; usb_n = 0;  // J
      #(`BIT_TIME);
      usb_p = 0; usb_n = 1;  // K
      #(`BIT_TIME);
      usb_p = 0; usb_n = 1;  // K
      #(`BIT_TIME);
      usb_p = 0; usb_n = 1;  // K
      #(`BIT_TIME);
      usb_p = 1; usb_n = 0;  // J
      #(`BIT_TIME);
      usb_p = 1; usb_n = 0;  // J
      #(`BIT_TIME);
      usb_p = 0; usb_n = 1;  // K
      #(`BIT_TIME);

      // end of packet
      usb_p = 0; usb_n = 0;  // Z
      #(`BIT_TIME);
      usb_p = 0; usb_n = 0;  // Z
      #(`BIT_TIME);
      usb_p = 1; usb_n = 0;  // J
      #(`BIT_TIME);
    end
*/

  // generate D+ signal
  initial
    begin
      // idle line
      usb_p = 1;
      #((`CLK_TICK * 12) + `P_SKEW);

      // clock sync
      usb_p = 0;  // K
      #(`P_LO_TIME);
      usb_p = 1;  // J
      #(`P_HI_TIME);
      usb_p = 0;  // K
      #(`P_LO_TIME);
      usb_p = 1;  // J
      #(`P_HI_TIME);
      usb_p = 0;  // K
      #(`P_LO_TIME);
      usb_p = 1;  // J
      #(`P_HI_TIME);
      usb_p = 0;  // K
      #(`P_LO_TIME);
      usb_p = 0;  // K
      #(`P_LO_TIME);

      // NAK packet
      usb_p = 1;  // J
      #(`P_HI_TIME);
      usb_p = 1;  // J
      #(`BIT_TIME);
      usb_p = 0;  // K
      #(`P_LO_TIME);
      usb_p = 0;  // K
      #(`BIT_TIME);
      usb_p = 0;  // K
      #(`BIT_TIME);
      usb_p = 1;  // J
      #(`P_HI_TIME);
      usb_p = 1;  // J
      #(`BIT_TIME);
      usb_p = 0;  // K
      #(`P_LO_TIME);

      // end of packet
      usb_p = 0;  // Z
      #(`BIT_TIME);
      usb_p = 0;  // Z
      #(`BIT_TIME);
      usb_p = 1;  // J
      #(`BIT_TIME);
    end

  // generate D- signal
  initial
    begin
      // idle line
      usb_n = 0;
      #((`CLK_TICK * 12) + `N_SKEW);

      // clock sync
      usb_n = 1;  // K
      #(`N_HI_TIME);
      usb_n = 0;  // J
      #(`N_LO_TIME);
      usb_n = 1;  // K
      #(`N_HI_TIME);
      usb_n = 0;  // J
      #(`N_LO_TIME);
      usb_n = 1;  // K
      #(`N_HI_TIME);
      usb_n = 0;  // J
      #(`N_LO_TIME);
      usb_n = 1;  // K
      #(`N_HI_TIME);
      usb_n = 1;  // K
      #(`N_HI_TIME);

      // NAK packet
      usb_n = 0;  // J
      #(`N_LO_TIME);
      usb_n = 0;  // J
      #(`BIT_TIME);
      usb_n = 1;  // K
      #(`N_HI_TIME);
      usb_n = 1;  // K
      #(`BIT_TIME);
      usb_n = 1;  // K
      #(`BIT_TIME);
      usb_n = 0;  // J
      #(`N_LO_TIME);
      usb_n = 0;  // J
      #(`BIT_TIME);
      usb_n = 1;  // K
      #(`N_HI_TIME);

      // end of packet
      usb_n = 0;  // Z
      #(`BIT_TIME);
      usb_n = 0;  // Z
      #(`BIT_TIME);
      usb_n = 0;  // J
      #(`BIT_TIME);
    end

  // generate chip clock
  reg clk = 0;
  always
    #(`CLK_TICK) clk = !clk;

  // instantiate usb receiver
  reg usb_p, usb_n;  // D+, D- signals
  wire ready;
  wire eop;
  wire [7:0] d_in;
  usb_rx USB_RX (
    .clk(clk),
    .usb_p(usb_p),
    .usb_n(usb_n),
    .ready(ready),
    .eop(eop),
    .data(d_in)
  );

endmodule