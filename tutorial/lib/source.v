// source.v
//
// synchronous data source
//

`default_nettype none

/**
       +--------------------+
       | source             |
       |                    |   Nd
------>|clk         data_out|---/-->
       |                    |
       |            do_valid|------>
       |                    |
       |         busy/_ready|<------
       |                    |
       +--------------------+
**/

module source #(
  parameter              Nd = 8           // number of data bits
) (
  input                  clk,             // clock signal

  output        [Nd-1:0] data_out,        // output data
  output                 do_valid,        // output valid
  input                  busy_ready       // 1=busy, 0=ready
);

  reg full = 1'b0;
  reg [Nd-1:0] data;
  reg valid = 1'b0;
  wire busy;

  assign data_out = data;
  assign do_valid = valid;
  assign busy = busy_ready;

  localparam N = 4;
  reg [7:0] msg [0:(1<<N)-1];
  reg [N-1:0] index = 0;
  initial
    begin
      msg[0] = "L";
      msg[1] = "o";
      msg[2] = "r";
      msg[3] = "e";
      msg[4] = "m";
      msg[5] = " ";
      msg[6] = "I";
      msg[7] = "p";
      msg[8] = "s";
      msg[9] = "u";
      msg[10] = "m";
      msg[11] = 8'h0D;
      msg[12] = 8'h0A;
    end

  // input interface
  always @(posedge clk)
    if (!full)
      begin
        data <= msg[index];
        index <= index + 1'b1;
        full <= 1'b1;
        if (!busy)
          valid <= 1'b1;
      end

  // output interface
  always @(posedge clk)
    if (!busy && full)
      valid <= 1'b1;
    else if (busy && valid)
      begin
        valid <= 1'b0;
        full <= 1'b0;
      end

endmodule
