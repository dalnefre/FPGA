/*

Synchronous FIFO Component

    +---------------+
    | fifo          |
    |               |
=N=>|i_data     i_rd|<---
--->|i_wr     o_data|=N=>
<---|o_full  o_empty|--->
    |               |
 +->|i_clk          |
 |  +---------------+

*/

`default_nettype none

module fifo #(
  parameter N = 8,                      // data bus bit width
  parameter N_ADDR = 4                  // address bit width
) (
  input             i_clk,              // system clock
  input             i_wr,               // write request
  input     [N-1:0] i_data,             // write data
  output            o_full,             // buffer full condition
  input             i_rd,               // read request
  output    [N-1:0] o_data,             // read data
  output            o_empty             // buffer empty condition
);
  localparam BUF_SIZE = 1 << N_ADDR;

  wire wr;                              // valid write request
  wire rd;                              // valid read request
  assign wr = i_wr && !o_full;
  assign rd = i_rd && !o_empty;

  // data buffer (memory)
  reg [N-1:0] buffer [0:BUF_SIZE-1];

  // maintain write pointer
  reg [N_ADDR:0] wr_addr;
  initial wr_addr = 0;
  always @(posedge i_clk)
    if (wr)
      wr_addr <= wr_addr + 1'b1;
  always @(posedge i_clk)  // NOTE: RAM access in its own block
    if (wr)
      buffer[wr_addr[N_ADDR-1:0]] <= i_data;

  // maintain read pointer
  reg [N_ADDR:0] rd_addr;
  initial rd_addr = 0;
  always @(posedge i_clk)
    if (rd)
      rd_addr <= rd_addr + 1'b1;
  assign o_data = buffer[rd_addr[N_ADDR-1:0]];

  // maintain queue length
  reg [N_ADDR:0] len;
  initial len = 0;
  always @(posedge i_clk)
    if (wr & !rd)
      len <= len + 1'b1;
    else if (!wr && rd)
      len <= len - 1'b1;
  assign o_empty = (len == 0);
  assign o_full = len[N_ADDR];//(len == BUF_SIZE);

/*
  // formal verification
  always @(*)
    assert(len == (wr_addr - rd_addr));
  always @(*)
    assert(len <= BUF_SIZE);
*/

endmodule
