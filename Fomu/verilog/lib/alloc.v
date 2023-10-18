/*

Linked-Memory Allocator

    +---------------+
    | alloc         |
    |               |
--->|i_alloc  i_free|<---
<=N=|o_addr   i_addr|<=N=
<---|o_ready  o_done|--->
    |               |
 +->|i_clk          |
 |  +---------------+

*/

`default_nettype none

module alloc #(
  parameter DATA_SZ = 16,               // number of bits per memory word
  parameter ADDR_SZ = 8,                // number of bits in each address
  parameter MEM_MAX = (1<<ADDR_SZ)      // maximum available physical memory
) (
  input             i_clk,              // domain clock
  input             i_alloc,            // allocation request
  input      [15:0] i_data,             // data assigned to allocation
  output reg [15:0] o_addr,             // allocated address
  output reg        o_ready,            // allocation ready (address valid)
  input             i_free,             // free request
  input      [15:0] i_addr,             // free address
  output reg        o_done              // free done (address released)
);
  // type-tag (4-msb)
  localparam DIR_TAG = 4'h8;            // direct(fixnum) or indirect(ptr)
  localparam MUT_TAG = 4'h4;            // mutable or immutable(rom) IFF indirect
  localparam OPQ_TAG = 4'h2;            // opaque(cap) or transparent(ram) IFF mutable
  localparam VLT_TAG = 4'h1;            // volatile or reserved IFF mutable

  // reserved rom locations
  localparam UNDEF  = 16'h0000;         // undefined value
  localparam NIL    = 16'h0001;         // the empty list
  localparam TRUE   = 16'h0002;         // boolean true
  localparam FALSE  = 16'h0003;         // boolean false
  localparam UNIT   = 16'h0004;         // inert result

/*
  // instantiate BRAM primitive
  wire [15:0] ram_rdata;
  wire [7:0] ram_raddr;
  wire ram_re;
  wire [15:0] ram_wdata;
  wire [7:0] ram_waddr;
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
    if (i_alloc && i_free)
      ram_cell[i_addr[7:0]] <= i_data;  // assign passed-thru memory
    else if (i_alloc && free_f)
      ram_cell[mem_next[7:0]] <= i_data;  // assign free-list memory
    else if (i_alloc)
      ram_cell[mem_top[7:0]] <= i_data;  // assign newly-allocated memory
  always @(posedge i_clk)  // NOTE: RAM access in its own block
    if (i_free && !i_alloc)
      ram_cell[i_addr[7:0]] <= mem_next;  // link free'd memory into free-list

  // request handler
  initial o_addr = UNDEF;
  initial o_ready = 1'b0;
  always @(posedge i_clk)
    if (i_alloc && i_free)
      begin
        o_addr <= i_addr;
        o_ready <= 1'b1;
      end
    else if (i_alloc && free_f)
      begin
        o_addr <= mem_next;
        o_ready <= 1'b1;
      end
    else if (i_alloc)
      begin
        o_addr <= mem_top;
        o_ready <= 1'b1;
      end
    else
      begin
        o_addr <= UNDEF;
        o_ready <= 1'b0;
      end
  initial o_done = 1'b0;
  always @(posedge i_clk)
    o_done <= i_free;

  // top of available memory
  reg [DATA_SZ-1:0] mem_top;
  initial mem_top = { (MUT_TAG | VLT_TAG), 12'h000 };
  always @(posedge i_clk)
    if (i_alloc && !i_free && !free_f)  // FIXME: handle out-of-memory condition!
      mem_top <= { mem_top[15:8], mem_top[7:0] + 1'b1 };

  // next memory cell on free-list
  reg [DATA_SZ-1:0] mem_next;
  initial mem_next = NIL;
  always @(posedge i_clk)
    if (i_free && !i_alloc)
      mem_next <= i_addr;
    else if (i_alloc && free_f)
      mem_next <= free_tail;

  // free-list non-empty flag
  wire free_f;
  assign free_f = mem_next[14];  // check MUT_TAG

  // tail of free-list (or NIL)
  wire [DATA_SZ-1:0] free_tail;
  assign free_tail = (free_f ? ram_cell[mem_next[7:0]] : NIL);

  // count of cells on free-list
  reg [DATA_SZ-1:0] mem_free;
  initial mem_free = {1'b1, 15'd0};  // fixnum +0
  always @(posedge i_clk)
    if (i_free && !i_alloc)
      mem_free <= mem_free + 1'b1;
    else if (i_alloc && !i_free && free_f)
      mem_free <= mem_free - 1'b1;

endmodule
