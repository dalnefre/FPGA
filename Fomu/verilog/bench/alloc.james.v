/*

A linked-memory quad allocator with configurable address and field sizes.

    +-----------------+
    | alloc           |
    |                 |
--->|i_al         i_wr|<---
=Q=>|i_adata   i_waddr|<=F=
<=F=|o_aaddr   i_wdata|<=Q=
    |                 |
--->|i_fr         i_rd|<---
=F=>|i_faddr   i_raddr|<=F=
    |          o_rdata|=Q=>
    |                 |
 +->|i_clk      o_full|--->
 |  +-----------------+

This component manages a dynamically-allocated memory heap.
It has two ports, with two functions each,
and a signal that indicates the memory is full.
Only one of the two ports may be used in any given cycle.
All results are available on the next clock-cycle.
Requests are pipelined and may be issued on every cycle.

The first port manages heap-allocation pointers.
An "alloc" request reserves a new address
and stores an initial quad there.
A "free" request returns memory to the heap.
Both requests can be serviced in the same cycle.
A "free" request must accompany an "alloc" request
if the memory is full.

The second port is a simple memory-access interface.
A "write" request stores a quad at a previously allocated address.
A "read" request retrieves the last quad stored at an address.

If an invalid request is issued, such as alloc-on-full or read+free,
the state of the component will become undefined.

A quad consists of four sequential fields, T, X, Y, and Z.
There are four fields in a quad.
Each field is a tagged value.

    <--------------- QUAD_SZ --------------->
    +---------+---------+---------+---------+
    |    T    |    X    |    Y    |    Z    |
    +---------+---------+---------+---------+
    <--------->
      FIELD_SZ

The allocator's storage comprises a number of 4kb memory blocks
arranged in a single row.
A single row seems to give better performance than a grid arrangement.
The block size is independent of the field size.
The total width of the row is the width of a quad.

    <---------------- QUAD_SZ -------------->
    +--------+   +--------+        +--------+  ^
    |        |   |        |        |        |  |
    |   4k   |   |   4k   |  ....  |   4k   |  | 2^ADDR_SZ
    |        |   |        |        |        |  |
    +--------+   +--------+        +--------+  v
                                   <-------->
                                   BLK_DATA_SZ
*/

`default_nettype none

`ifdef __ICARUS__
`include "bram.v"
`else
`include "bram4k.v"
`endif

module alloc #(
    parameter FIELD_SZ = 16,                // number of bits in a tagged value
    parameter ADDR_SZ = 8,                  // log2(size of the address space), not more than FIELD_SZ-4
    // The following parameters can be adjusted for testing purposes. The
    // quantity BLK_DATA_SZ * 2^ADDR_SZ must not exceed 4096.
    parameter BLK_DATA_SZ = 16              // memory cell size in bits, per block
) (
    input                       i_clk,      // domain clock

    input                       i_al,       // allocation request
    input       [QUAD_SZ-1:0]   i_adata,    // initial data
    output reg  [FIELD_SZ-1:0]  o_aaddr,    // allocated address

    input                       i_fr,       // free request
    input       [FIELD_SZ-1:0]  i_faddr,    // free address

    input                       i_wr,       // write request
    input       [FIELD_SZ-1:0]  i_waddr,    // write address
    input       [QUAD_SZ-1:0]   i_wdata,    // data written

    input                       i_rd,       // read request
    input       [FIELD_SZ-1:0]  i_raddr,    // read address
    output      [QUAD_SZ-1:0]   o_rdata,    // data read

    output                      o_full      // memory full condition
);
    localparam QUAD_SZ = 4 * FIELD_SZ;      // memory cell size in bits
    localparam NR_BLKS = QUAD_SZ / BLK_DATA_SZ;

    // type tags
    localparam DIR_TAG = 1 << 3;    // direct(fixnum) or indirect(ptr)
    localparam MUT_TAG = 1 << 2;    // mutable or immutable(rom)
    localparam OPQ_TAG = 1 << 1;    // opaque(cap) or transparent(ram)
    localparam VLT_TAG = 1;         // volatile or reserved
    localparam RAM_TAG = MUT_TAG | VLT_TAG;
    localparam BASE = RAM_TAG << (FIELD_SZ-4);
    localparam FREE_T = 15;         // T field for a quad in the free list
    localparam FREE_QUAD = (FREE_T << (3*FIELD_SZ)) | BASE; // [T ... Z]

    // top of available memory
    reg [ADDR_SZ:0] mem_top = 0;
    // no more memory available (hard limit)
    wire full_f = mem_top[ADDR_SZ];

    // count of cells on free-list (negative if empty)
    reg [ADDR_SZ:0] mem_free = -1;
    // cells are available on the free-list
    wire free_f = !mem_free[ADDR_SZ];
    assign o_full = full_f && !free_f;

    // raise the memory ceiling?
    wire raise_top = i_al && !i_fr && !free_f;

    // whether a cell is being pushed onto or popped from the free list
    wire pop_free = i_al && !i_fr && free_f;
    wire push_free = i_fr && !i_al;
    // previous operation was pop_free
    reg r_pop_freed = 1'b0;

    // enable/disable BRAM requests
    wire wr_en = i_al || i_fr || i_wr;
    wire rd_en = i_rd || pop_free;

    // the data read from BRAM
    wire [QUAD_SZ-1:0] rdata;

    // next memory cell on free-list
    reg [ADDR_SZ-1:0] r_mem_next = 0;
    wire [ADDR_SZ-1:0] mem_next = (
        r_pop_freed
        ? rdata[ADDR_SZ-1:0]
        : r_mem_next
    );
    wire [QUAD_SZ-1:0] fdata = FREE_QUAD | mem_next; // [FREE_T, #?, #?, Z]

    // determine the abstract memory locations to read/write
    wire [ADDR_SZ-1:0] waddr = (
        i_fr
        ? i_faddr[ADDR_SZ-1:0] // if also i_al, assign passed-thru memory
        : (
            i_al
            ? (
                free_f
                ? mem_next
                : mem_top[ADDR_SZ-1:0]
            )
            : i_waddr[ADDR_SZ-1:0]
        )
    );
    wire [ADDR_SZ-1:0] raddr = (
        pop_free
        ? mem_next
        : i_raddr
    );

    // instantiate the grid of blocks
    genvar blk_nr;
    for (blk_nr = 0; blk_nr < NR_BLKS; blk_nr = blk_nr + 1) begin
        localparam ms = BLK_DATA_SZ * (blk_nr + 1) - 1;
        localparam ls = BLK_DATA_SZ * blk_nr;
        bram #(
            .ADDR_SZ(ADDR_SZ),
            .DATA_SZ(BLK_DATA_SZ)
        ) BRAM (
            .i_clk(i_clk),
            .i_wr_en(wr_en),
            .i_waddr(waddr),
            .i_wdata(
                i_al
                ? i_adata[ms:ls]
                : (
                    i_fr
                    ? fdata[ms:ls]
                    : i_wdata[ms:ls]
                )
            ),
            .i_rd_en(rd_en),
            .i_raddr(raddr),
            .o_rdata(rdata[ms:ls])
        );
    end

    assign o_rdata = rdata;
    always @(posedge i_clk) begin
        // register the allocated address (garbage if i_al is low)
        o_aaddr <= BASE | (
            i_fr
            ? i_faddr
            : (
                free_f
                ? mem_next
                : mem_top[ADDR_SZ-1:0]
            )
        );
        // increment memory top marker
        if (raise_top) begin
            mem_top <= mem_top + 1;
        end
        // maintain the free list
        if (r_pop_freed) begin
            r_mem_next <= rdata[ADDR_SZ-1:0]; // pop
        end
        r_pop_freed <= pop_free;
        if (push_free) begin
            r_mem_next <= i_faddr[ADDR_SZ-1:0]; // push
        end
        // maintain free list counter
        if (pop_free) begin
            mem_free <= mem_free - 1'b1;
        end else if (push_free) begin
            mem_free <= mem_free + 1'b1;
        end
    end
endmodule
