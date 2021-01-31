// debounce_tb.v
//
// simulation test bench for debounce.v
//

module test_bench;

  localparam CLK_FREQ = 256;

  // dump simulation signals
  initial
    begin
      $dumpfile("debounce.vcd");
      $dumpvars(0, test_bench);
      #(CLK_FREQ * 2);  // run for 1 "second"
      $finish;  // stop simulation
    end

  // simulated input pin
  reg pin = 0;
  always
    begin
      #1 pin <= ~pin;
      #17 pin <= ~pin;
      #2 pin <= ~pin;
      #14 pin <= ~pin;
      #1 pin <= ~pin;
      #2 pin <= ~pin;
      #3 pin <= ~pin;
      #5 pin <= ~pin;
      #3 pin <= ~pin;
      #2 pin <= ~pin;
      #1 pin <= ~pin;
    end
/*
    begin
      #1 pin <= ~pin;
      #2 pin <= ~pin;
      #3 pin <= ~pin;
      #4 pin <= ~pin;
      #5 pin <= ~pin;
      #6 pin <= ~pin;
      #7 pin <= ~pin;
      #8 pin <= ~pin;
      #9 pin <= ~pin;
      #10 pin <= ~pin;
      #11 pin <= ~pin;
      #12 pin <= ~pin;
      #11 pin <= ~pin;
      #10 pin <= ~pin;
      #9 pin <= ~pin;
      #8 pin <= ~pin;
      #7 pin <= ~pin;
      #6 pin <= ~pin;
      #5 pin <= ~pin;
      #4 pin <= ~pin;
      #3 pin <= ~pin;
      #2 pin <= ~pin;
      #1 pin <= ~pin;
    end
*/
/*
    begin
      #25 pin <= ~pin;
      #2 pin <= ~pin;
      #2 pin <= ~pin;
      #12 pin <= ~pin;
      #2 pin <= ~pin;
    end
*/

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate synchronizer
  async #(
    .N_DFF(2)
  ) SYNC (
    .clk(clk),
    .async_in(pin),
    .sync_out(btn)
  );
  wire btn;

  // instantiate device-under-test
  debounce #(
    .MIN_TIME(3)
  ) DUT (
    .clk(clk),
    .in(btn),
    .out(led)
  );
  wire led;

  // instantiate device-under-test
  hyster #(
    .MIN_TIME(5)
  ) DUT2 (
    .clk(clk),
    .in(btn),
    .out(led2)
  );
  wire led2;

endmodule
