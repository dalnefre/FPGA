/*

A linked-memory allocator with configurable address and data sizes.

    +-----------------+
    | alloc           |
    |                 |
--->|i_al         i_wr|<---
=N=>|i_adata   i_waddr|<=N=
<=N=|o_aaddr   i_wdata|<=N=
    |                 |
--->|i_fr         i_rd|<---
=N=>|i_faddr   i_raddr|<=N=
    |          o_rdata|=N=>
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
and stores an initial data value there.
A "free" request returns memory to the heap.
Both requests can be serviced in the same cycle.
A "free" request must accompany an "alloc" request
if the memory is full.

The second port is a simple memory-access interface.
A "write" request stores data at a previously allocated address.
A "read" request retrieves the last data stored at an address.

If an invalid request is issued, such as alloc-on-full or read+free,
the component will move to an undefined state.

This component comprises a number of 4kb memory blocks arranged in a single row.
A single row seems to give better performance than a grid arrangement.
The width of each memory cell (DATA_SZ) is the combined width of all blocks.

                       DATA_SZ
    |----------------------------------------|

    +--------+   +--------+         +--------+   ---
    |        |   |        |         |        |    |
    |   4k   |   |   4k   |   ...   |   4k   |    | 2^ADDR_SZ
    |        |   |        |         |        |    |
    +--------+   +--------+         +--------+   ---

                                    |--------|
                                    BLK_DATA_SZ
*/

`default_nettype none

`ifdef __ICARUS__
`include "bram.v"
`else
`include "bram4k.v"
`endif

module alloc #(
    parameter ADDR_SZ = 8,                  // number of bits in each address
    parameter DATA_SZ = 16,                 // memory cell size in bits, not less than ADDR_SZ
    // The following parameters can be adjusted for testing purposes. The
    // quantity BLK_DATA_SZ * 2^ADDR_SZ must not exceed 4096.
    parameter BLK_DATA_SZ = 16              // memory cell size in bits, per block
) (
    input                       i_clk,      // domain clock

    input                       i_al,       // allocation request
    input         [DATA_SZ-1:0] i_adata,    // initial data
    output reg    [ADDR_SZ-1:0] o_aaddr,    // allocated address

    input                       i_fr,       // free request
    input         [ADDR_SZ-1:0] i_faddr,    // free address

    input                       i_wr,       // write request
    input         [ADDR_SZ-1:0] i_waddr,    // write address
    input         [DATA_SZ-1:0] i_wdata,    // data written

    input                       i_rd,       // read request
    input         [ADDR_SZ-1:0] i_raddr,    // read address
    output        [DATA_SZ-1:0] o_rdata,    // data read

    output                      o_full      // memory full condition
);
    localparam NR_BLKS = DATA_SZ / BLK_DATA_SZ;

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
    wire [DATA_SZ-1:0] rdata;

    // next memory cell on free-list
    reg [DATA_SZ-1:0] r_mem_next = 0;
    wire [DATA_SZ-1:0] mem_next = (
        r_pop_freed
        ? rdata
        : r_mem_next
    );

    // determine the abstract memory locations to read/write
    wire [ADDR_SZ-1:0] waddr = (
        i_fr
        ? i_faddr // if also i_al, assign passed-thru memory
        : (
            i_al
            ? (
                free_f
                ? mem_next[ADDR_SZ-1:0]
                : mem_top[ADDR_SZ-1:0]
            )
            : i_waddr
        )
    );
    wire [ADDR_SZ-1:0] raddr = (
        pop_free
        ? mem_next[ADDR_SZ-1:0]
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
            .i_waddr(waddr[ADDR_SZ-1:0]),
            .i_wdata(
                i_al
                ? i_adata[ms:ls]
                : (
                    i_fr
                    ? mem_next[ms:ls]
                    : i_wdata[ms:ls]
                )
            ),
            .i_rd_en(rd_en),
            .i_raddr(raddr[ADDR_SZ-1:0]),
            .o_rdata(rdata[ms:ls])
        );
    end

    assign o_rdata = rdata;
    always @(posedge i_clk) begin
        // register the allocated address (garbage if i_al if low)
        o_aaddr <= (
            i_fr
            ? i_faddr
            : (
                free_f
                ? mem_next[ADDR_SZ-1:0]
                : mem_top[ADDR_SZ-1:0]
            )
        );
        // increment memory top marker
        if (raise_top) begin
            mem_top <= mem_top + 1;
        end
        // maintain the free list
        if (r_pop_freed) begin
            r_mem_next <= rdata; // pop
        end
        r_pop_freed <= pop_free;
        if (push_free) begin
            r_mem_next <= i_faddr; // push
        end
        // maintain free list counter
        if (pop_free) begin
            mem_free <= mem_free - 1'b1;
        end else if (push_free) begin
            mem_free <= mem_free + 1'b1;
        end
    end
endmodule
