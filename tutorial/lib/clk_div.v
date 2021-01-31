// clk_div.v
//
// clock frequency divider
//

module clk_div #(
  parameter              N_DIV = 8        // number of clock divisions
) (
  input                  clk_i,           // input clock (@ CLK_FREQ)
  output                 clk_o            // output clock (CLK_FREQ >> N_DIV)
);

  reg [N_DIV-1:0] div;  // clock divisions

  initial
    div = 1;

  always @(posedge clk_i)
    div[0] <= ~div[0];

  genvar i;
  generate
    for (i = 0; i < N_DIV-1; i = i+1)
      always @(posedge div[i])
        div[i+1] <= ~div[i+1];
  endgenerate

  assign clk_o = ~div[N_DIV-1];

endmodule

/**

# Minimizing Division Error

## Fomu Clock Divisions

| N_DIV | Frequency   | Period        | Error  |
|-------|-------------|---------------|--------|
| 0     |  48.000 MHz |  20.833... ns |  0%    |
| 10    |  46.875 kHz |  21.333... μs |  0%    |
| 18    | 183.000  Hz |   5.46448  ms | -0.06% |

## TinyFPGA-BX Clock Divisions

| N_DIV | Frequency   | Period        | Error  |
|-------|-------------|---------------|--------|
| 0     |  16.000 MHz |  62.500    ns |  0%    |
| 10    |  15.625 kHz |  64.000    μs |  0%    |
| 18    |  61.000  Hz |  16.39344  ms | -0.06% |

**/
