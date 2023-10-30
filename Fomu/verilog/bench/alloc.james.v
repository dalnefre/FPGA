/*

Linked-Memory Allocator

    +---------------+
    | alloc         |
    |               |
--->|i_alloc    i_wr|<---
=N=>|i_data  i_wdata|<=N=
<=N=|o_addr  i_waddr|<=N=
    |               |
--->|i_free     i_rd|<---
=N=>|i_addr  i_raddr|<=N=
    |        o_rdata|=N=>
    |               |
 +->|i_clk     o_err|--->
 |  +---------------+

This component manages a dynamically-allocated memory heap.
It has two ports, with two functions each, and an error signal.
Only one of the two ports may be used in any given cycle.
All results are available on the next clock-cycle.
Requests are pipelined and may be issued on every cycle.

The first port manages heap-allocation pointers.
An "alloc" request reserves a new address
and stores an initial data value there.
A "free" request returns memory to the heap.
Both requests can be serviced in the same cycle.

The second port is a simple memory-access interface.
A "write" request stores data at a previously allocated address.
A "read" request retrieves the last data stored at an address.

If an error (such as out-of-memory) or invalid request occurs,
the error signal is raised and the component halts.

*/

`default_nettype none

`ifdef __ICARUS__
`include "bram.v"
`else
`include "bram4k.v"
`endif

module alloc #(
    // WARNING: hard-coded contants assume `DATA_SZ` = 16
    parameter DATA_SZ           = 16,                           // number of bits per memory word
    parameter ADDR_SZ           = 8,                            // number of bits in each address
    parameter MEM_MAX           = (1<<ADDR_SZ)                  // maximum available physical memory
) (
    input                       i_clk,                          // domain clock

    input                       i_alloc,                        // allocation request
    input         [DATA_SZ-1:0] i_data,                         // initial data
    output reg    [DATA_SZ-1:0] o_addr,                         // allocated address

    input                       i_free,                         // free request
    input         [DATA_SZ-1:0] i_addr,                         // free address

    input                       i_wr,                           // write request
    input         [DATA_SZ-1:0] i_waddr,                        // write address
    input         [DATA_SZ-1:0] i_wdata,                        // data written

    input                       i_rd,                           // read request
    input         [DATA_SZ-1:0] i_raddr,                        // read address
    output        [DATA_SZ-1:0] o_rdata,                        // data read

    output reg                  o_err                           // error condition
);

    // type-tags
    localparam DIR_TAG          = 16'h8000;                     // direct(fixnum) or indirect(ptr)
    localparam MUT_TAG          = 16'h4000;                     // mutable or immutable(rom)
    localparam OPQ_TAG          = 16'h2000;                     // opaque(cap) or transparent(ram)
    localparam VLT_TAG          = 16'h1000;                     // volatile or reserved

    // reserved constants
    localparam UNDEF            = 16'h0000;                     // undefined value
    localparam NIL              = 16'h0001;                     // the empty list
    localparam TRUE             = 16'h0002;                     // boolean true
    localparam FALSE            = 16'h0003;                     // boolean false
    localparam UNIT             = 16'h0004;                     // inert result
    localparam ZERO             = 16'h8000;                     // fixnum +0

    initial o_addr = UNDEF;
    initial o_err = 1'b0;
    assign o_rdata = rdata;

    wire ptr_op = i_alloc || i_free;
    wire mem_op = i_rd || i_wr;
    wire bad_op = ptr_op && mem_op;
    wire read_op = i_rd && !ptr_op;
    wire write_op = i_wr && !ptr_op;
    wire alloc_op = i_alloc && !mem_op;
    wire free_op = i_free && !mem_op;

    // top of available memory
    reg [DATA_SZ-1:0] mem_top = (MUT_TAG | VLT_TAG);
    wire mem_full = mem_top[ADDR_SZ];

    // count of cells on free-list (always non-negative)
    reg [ADDR_SZ:0] mem_free = 0;
    // cells are available on the free-list
    wire free_f = (mem_free != 0);

    // raise the memory ceiling?
    wire raise_top = alloc_op && !free_op && !free_f;

    // whether a cell is being pushed onto or popped from the free list
    wire pop_free_op = alloc_op && !free_op && free_f;
    wire push_free_op = free_op && !alloc_op;

    // the data read from BRAM
    wire [DATA_SZ-1:0] rdata;

    // next memory cell on free-list
    reg [DATA_SZ-1:0] mem_next_reg = NIL;
    reg pop_rdy = 0;
    wire [DATA_SZ-1:0] mem_next = (
        pop_rdy
        ? rdata
        : mem_next_reg
    );

    bram BRAM (
        .i_clk(i_clk),
        .i_wr_en(alloc_op || free_op || write_op),
        .i_waddr(
            free_op
            ? i_addr[ADDR_SZ-1:0] // if also alloc_op, assign passed-thru memory
            : (
                alloc_op
                ? (
                    free_f
                    ? mem_next[ADDR_SZ-1:0]
                    : mem_top[ADDR_SZ-1:0]
                )
                : i_waddr[ADDR_SZ-1:0]
            )
        ),
        .i_wdata(
            alloc_op
            ? i_data
            : (
                free_op
                ? mem_next
                : i_wdata
            )
        ),
        .i_rd_en(read_op || pop_free_op),
        .i_raddr(
            pop_free_op
            ? mem_next[ADDR_SZ-1:0]
            : i_raddr[ADDR_SZ-1:0]
        ),
        .o_rdata(rdata)
    );

    always @(posedge i_clk) begin
        // check for error conditions
        if (bad_op || (raise_top && mem_full)) begin
            o_err <= 1;
        end else begin
            o_err <= 0;  // strobe, not sticky...
            // register the allocated address
            o_addr <= (
                alloc_op
                ? (
                    free_op
                    ? i_addr
                    : (
                        free_f
                        ? mem_next
                        : mem_top
                    )
                )
                : UNDEF
            );
            // increment memory top marker
            if (raise_top && !mem_full) begin
                mem_top <= mem_top + 1;
            end
            // maintain the free list
            if (pop_rdy) begin
                mem_next_reg <= rdata; // pop
            end
            pop_rdy <= pop_free_op;
            if (push_free_op) begin
                mem_next_reg <= i_addr; // push
            end
            // maintain free list counter
            if (pop_free_op) begin
                mem_free <= mem_free - 1'b1;
            end else if (push_free_op) begin
                mem_free <= mem_free + 1'b1;
            end
        end
    end
endmodule
