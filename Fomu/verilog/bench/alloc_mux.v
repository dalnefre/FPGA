/*

A linked-memory allocator with a variable address size. It works by spreading
its address space over several memory blocks.

It has the same signal interface as alloc.v, but accepts different parameters.
Instead of the address size being set explicitly with an ADDR_SZ parameter, it
is implied by the NR_BLKS parameter.

*/

`default_nettype none

`include "alloc.james.v"

module alloc_mux #(
    parameter ADDR_SZ = 9                           // number of bits per address (max 12)
) (
    input                           i_clk,          // domain clock

    input                           i_alloc,        // allocation request
    input       [DATA_SZ-1:0]       i_data,         // initial data
    output                          o_full,         // space exhausted
    output      [ADDR_SZ-1:0]       o_addr,         // allocated address

    input                           i_free,         // free request
    input       [ADDR_SZ-1:0]       i_addr,         // free address

    input                           i_wr,           // write request
    input       [ADDR_SZ-1:0]       i_waddr,        // write address
    input       [DATA_SZ-1:0]       i_wdata,        // data written

    input                           i_rd,           // read request
    input       [ADDR_SZ-1:0]       i_raddr,        // read address
    output      [DATA_SZ-1:0]       o_rdata,        // data read

    output                          o_err           // error condition
);
    localparam SUB_ADDR_SZ = 8;                     // address size within each block
    localparam BLK_ADDR_SZ = ADDR_SZ - SUB_ADDR_SZ; // address size of blocks themselves
    localparam NR_BLKS = 1<<BLK_ADDR_SZ;            // number of memory blocks to use
    localparam DATA_SZ = 16;                        // cell size

// Collect the allocators' single-bit outputs into vectors.

    wire [NR_BLKS-1:0] err;
    assign o_err = |err;
    wire [NR_BLKS-1:0] full;
    // assign o_full = &full; // FIXME: is this faster than using alloc_blk_nr?

// Find a block with free space, or produce an index out of range if there isn't
// one. This involves finding the position of any zero bit in 'full'.

    wire [BLK_ADDR_SZ:0] alloc_blk_nr = (
        (NR_BLKS > 0 && !full[0]) ? 0 :
        (NR_BLKS > 1 && !full[1]) ? 1 :
        (NR_BLKS > 2 && !full[2]) ? 2 :
        (NR_BLKS > 3 && !full[3]) ? 3 :
        (NR_BLKS > 4 && !full[4]) ? 4 :
        (NR_BLKS > 5 && !full[5]) ? 5 :
        (NR_BLKS > 6 && !full[6]) ? 6 :
        (NR_BLKS > 7 && !full[7]) ? 7 :
        (NR_BLKS > 8 && !full[8]) ? 8 :
        (NR_BLKS > 9 && !full[9]) ? 9 :
        (NR_BLKS > 10 && !full[10]) ? 10 :
        (NR_BLKS > 11 && !full[11]) ? 11 :
        (NR_BLKS > 12 && !full[12]) ? 12 :
        (NR_BLKS > 13 && !full[13]) ? 13 :
        (NR_BLKS > 14 && !full[14]) ? 14 :
        (NR_BLKS > 15 && !full[15]) ? 15 :
        NR_BLKS
    );
    assign o_full = alloc_blk_nr[BLK_ADDR_SZ];

// Extract the block number from the address.

    wire [BLK_ADDR_SZ-1:0] free_blk_nr = i_addr[ADDR_SZ-1:SUB_ADDR_SZ];
    wire [BLK_ADDR_SZ-1:0] wr_blk_nr = i_waddr[ADDR_SZ-1:SUB_ADDR_SZ];
    wire [BLK_ADDR_SZ-1:0] rd_blk_nr = i_raddr[ADDR_SZ-1:SUB_ADDR_SZ];

// Construct the allocated address, incorporating into it the block number.

    wire [SUB_ADDR_SZ-1:0] addrs [0:NR_BLKS-1];
    reg [BLK_ADDR_SZ-1:0] r_alloc_blk_nr;
    always @(posedge i_clk) begin
        r_alloc_blk_nr <= alloc_blk_nr[BLK_ADDR_SZ-1:0];
    end
    assign o_addr = {r_alloc_blk_nr, addrs[r_alloc_blk_nr]};

// Attach the read data to the output.

    wire [DATA_SZ-1:0] rdatas [0:NR_BLKS-1];
    reg [BLK_ADDR_SZ-1:0] r_rd_blk_nr;
    always @(posedge i_clk) begin
        r_rd_blk_nr <= rd_blk_nr;
    end
    assign o_rdata = rdatas[r_rd_blk_nr];

// Instantiate the blocks.

    generate
        genvar blk_nr;
        for (blk_nr = 0; blk_nr < NR_BLKS; blk_nr = blk_nr + 1) begin
            alloc #(
                .ADDR_SZ(SUB_ADDR_SZ)
            ) ALLOC (
                .i_clk(i_clk),
                .i_alloc(i_alloc && alloc_blk_nr == blk_nr),
                .i_data(i_data),
                .o_full(full[blk_nr]),
                .o_addr(addrs[blk_nr]),
                .i_free(i_free && free_blk_nr == blk_nr),
                .i_addr(i_addr),
                .i_wr(i_wr && wr_blk_nr == blk_nr),
                .i_waddr(i_waddr[SUB_ADDR_SZ-1:0]),
                .i_wdata(i_wdata),
                .i_rd(i_rd && rd_blk_nr == blk_nr),
                .i_raddr(i_raddr[SUB_ADDR_SZ-1:0]),
                .o_rdata(rdatas[blk_nr]),
                .o_err(err[blk_nr])
            );
        end
    endgenerate
endmodule
