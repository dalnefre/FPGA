// buffer_tb.v
//
// simulation test bench for buffer.v
//

module test_bench;

  localparam CLK_FREQ = 32;
  localparam Nd = 8;           // number of data bits

  // dump simulation signals
  initial
    begin
      $dumpfile("buffer.vcd");
      $dumpvars(0, test_bench);
      #(CLK_FREQ * 2);  // run for 1 "second"
      $finish;  // stop simulation
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate data source
  source #(
    .Nd(Nd)
  ) SRC (
    .clk(clk),
    .data_out(DIN),
    .do_valid(wr),
    .busy_ready(full)
  );

  wire [Nd-1:0] DIN;
  wire wr;
  wire full;

  // instantiate device-under-test
  buffer #(
    .Nd(Nd)
  ) DUT (
    .clk(clk),
    .data_in(DIN),
    .di_valid(wr),
    .full_empty(full),
    .data_out(DIN2),
    .do_valid(wr2),
    .busy_ready(full2)
  );

  wire [Nd-1:0] DIN2;
  wire wr2;
  wire full2;

  // instantiate 2nd device-under-test
  buffer #(
    .Nd(Nd)
  ) DUT2 (
    .clk(clk),
    .data_in(DIN2),
    .di_valid(wr2),
    .full_empty(full2),
    .data_out(DOUT),
    .do_valid(valid),
    .busy_ready(busy)
  );

  wire [Nd-1:0] DOUT;
  wire valid;
  reg busy;

  initial
    begin
      busy = 1'b0;
      #(CLK_FREQ);
      busy = 1'b1;
      #(CLK_FREQ / 2);
      busy = 1'b0;
    end

endmodule
