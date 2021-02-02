// buffer.v
//
// synchronous data buffer
//

`default_nettype none

/**
       +----------------------------+
       | buffer                     |
       |                            |
------>|clk                         |
   Nd  |                            |   Nd
---/-->|data_in             data_out|---/-->
       |                            |
------>|di_valid            do_valid|------>
       |                            |
<------|full/_empty      busy/_ready|<------
       |                            |
       +----------------------------+
**/

module buffer #(
  parameter              Nd = 8           // number of data bits
) (
  input                  clk,             // clock signal

  input         [Nd-1:0] data_in,         // input data
  input                  di_valid,        // input valid
  output                 full_empty,      // 1=full, 0=empty

  output        [Nd-1:0] data_out,        // output data
  output                 do_valid,        // output valid
  input                  busy_ready       // 1=busy, 0=ready
);

  reg full = 1'b0;
  reg [Nd-1:0] data;
  reg valid = 1'b0;
  wire busy = busy_ready;

  assign full_empty = full;
  assign data_out = data;
  assign do_valid = valid;

  // input interface
  always @(posedge clk)
    if (!full && di_valid)
      begin
        data <= data_in;
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
