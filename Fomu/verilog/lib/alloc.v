/*

Linked-Memory Allocator

    +---------------+
    | alloc         |
    |               |
--->|i_wr       i_rd|<---
=N=>|i_data   o_data|=N=>
--->|i_alloc  i_free|<---
<=N=|o_addr   i_addr|<=N=
<---|o_ready  o_done|--->
    |          o_err|--->
 +->|i_clk          |
 |  +---------------+

*/

`default_nettype none

module alloc #(
  parameter ADDR_SZ = 8,                // number of bits in each address
  parameter MEM_MAX = (1<<ADDR_SZ)      // maximum available physical memory
) (
  input             i_clk,              // domain clock
  input             i_wr,               // write request
  input      [15:0] i_data,             // data written
  input             i_alloc,            // allocation request
  output reg [15:0] o_addr,             // allocated address
  output reg        o_ready,            // allocation ready (address valid)
  input             i_rd,               // read request
  output reg [15:0] o_data,             // data read
  input             i_free,             // free request
  input      [15:0] i_addr,             // free address
  output reg        o_done,             // free done (address released)
  output reg        o_err               // error condition
);
  // WARNING: hard-coded contants assume `DATA_SZ` = 16
  parameter DATA_SZ = 16;               // number of bits per memory word

  // type-tags
  localparam DIR_TAG = 16'h8000;        // direct(fixnum) or indirect(ptr)
  localparam MUT_TAG = 16'h4000;        // mutable or immutable(rom) IFF indirect
  localparam OPQ_TAG = 16'h2000;        // opaque(cap) or transparent(ram) IFF mutable
  localparam VLT_TAG = 16'h1000;        // volatile or reserved IFF mutable

  // reserved constants
  localparam UNDEF  = 16'h0000;         // undefined value
  localparam NIL    = 16'h0001;         // the empty list
  localparam TRUE   = 16'h0002;         // boolean true
  localparam FALSE  = 16'h0003;         // boolean false
  localparam UNIT   = 16'h0004;         // inert result
  localparam ZERO   = 16'h8000;         // fixnum +0

/*
  // instantiate BRAM primitive
  wire [DATA_SZ-1:0] ram_rdata;
  wire [ADDR_SZ-1:0] ram_raddr;
  wire ram_re;
  wire [DATA_SZ-1:0] ram_wdata;
  wire [ADDR_SZ-1:0] ram_waddr;
  wire ram_we;
  SB_RAM256x16 ram_cell (
    .RDATA(ram_rdata),
    .RADDR(ram_raddr),
    .RCLK(i_clk),
    .RCLKE(1'b1),
    .RE(ram_re),
    .WDATA(ram_wdata),
    .WADDR(ram_waddr),
    .WCLK(i_clk),
    .WCLKE(1'b1),
    .WE(ram_we),
    .MASK(16'hFFFF)
  );
*/
  // dynamically managed memory
  reg [DATA_SZ-1:0] ram_cell [0:MEM_MAX-1];
  always @(posedge i_clk)  // NOTE: RAM access in its own block
    if (!i_rd && !i_wr) begin
      if (i_alloc && i_free)
        ram_cell[i_addr[ADDR_SZ-1:0]] <= i_data;  // assign passed-thru memory
      else if (i_alloc && free_f)
        ram_cell[mem_next[ADDR_SZ-1:0]] <= i_data;  // assign free-list memory
      else if (i_alloc)
        ram_cell[mem_top[ADDR_SZ-1:0]] <= i_data;  // assign newly-allocated memory
    end else if (i_wr)
      ram_cell[i_addr[ADDR_SZ-1:0]] <= i_data;  // write memory
  always @(posedge i_clk)  // NOTE: RAM access in its own block
    if (!i_rd && !i_wr && !i_alloc && i_free)
      ram_cell[i_addr[ADDR_SZ-1:0]] <= mem_next;  // link free'd memory into free-list

  // request handler
  initial o_addr = UNDEF;
  initial o_ready = 1'b0;
  always @(posedge i_clk)
    if (!i_rd && !i_wr) begin
      if (i_alloc && i_free) begin
        o_addr <= i_addr;
        o_ready <= 1'b1;
      end else if (i_alloc && free_f) begin
        o_addr <= mem_next;
        o_ready <= 1'b1;
      end else if (i_alloc) begin
        o_addr <= mem_top;
        o_ready <= 1'b1;
      end else begin
        o_addr <= UNDEF;
        o_ready <= 1'b0;
      end
    end
  initial o_done = 1'b0;
  always @(posedge i_clk)
    o_done <= i_free;

  // top of available memory
  reg [DATA_SZ-1:0] mem_top;
  initial mem_top = (MUT_TAG | VLT_TAG);
  wire [ADDR_SZ:0] next_top;  // extra bit for overflow check
  // FIXME: pre-compute `next_top` and register result?
  assign next_top = { 1'b0, mem_top[ADDR_SZ-1:0] } + 1'b1;
  always @(posedge i_clk)
    if (!i_rd && !i_wr && i_alloc && !i_free && !free_f) begin
      if (next_top[ADDR_SZ])  // overflow check
        o_err <= 1'b1;  // out-of-memory condition!
      else
        mem_top <= { mem_top[DATA_SZ-1:ADDR_SZ+1], next_top };
    end

  // next memory cell on free-list
  initial o_data = UNDEF;
  reg [DATA_SZ-1:0] mem_next;
  initial mem_next = NIL;
  always @(posedge i_clk) begin
    o_data <= UNDEF;
    if (!i_rd && !i_wr) begin
      if (!i_alloc && i_free)
        mem_next <= i_addr;
      else if (i_alloc && !i_free && free_f)
        mem_next <= ram_cell[mem_next[ADDR_SZ-1:0]];
    end else if (i_rd)
      o_data <= ram_cell[i_addr[ADDR_SZ-1:0]];
  end

  // free-list non-empty flag
  wire free_f;
  assign free_f = mem_next[14];  // check MUT_TAG

  // count of cells on free-list (always non-negative)
  reg [DATA_SZ-1:0] mem_free;
  initial mem_free = ZERO;  // fixnum
  always @(posedge i_clk)
    if (!i_rd && !i_wr) begin
      if (!i_alloc && i_free)
        mem_free <= mem_free + 1'b1;
      else if (i_alloc && !i_free && free_f)
        mem_free <= mem_free - 1'b1;
    end

endmodule
