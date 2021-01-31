// source.v
//
// synchronous data source
//

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

  always @(posedge clk)
    if (!full)
      begin
        case (data)
          "K" :
            data <= "S";
          "S" :
            data <= "O";
          default :
            data <= "K";
        endcase
        full <= 1'b1;
      end

  assign data_out = data;
  assign do_valid = valid;
  assign busy = busy_ready;

  always @(posedge clk)
    if (!busy && full)
      begin
        valid <= 1'b1;
        full <= 1'b0;
      end
    else
      valid <= 1'b0;

/*
  always @(posedge clk)
    if (!full)
      begin
        case (data)
          "K" :
            data <= "S";
          "S" :
            data <= "O";
          default :
            data <= "K";
        endcase
        full <= 1'b1;
      end
    else if (!busy)
      valid <= 1'b1;
    else
      begin
        full <= 1'b0;
        valid <= 1'b0;
      end

  assign busy = busy_ready;
  assign data_out = data;
  assign do_valid = valid;
*/

endmodule
