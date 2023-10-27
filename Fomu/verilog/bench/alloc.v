/*

Linked-Memory Allocator

    +---------------+
    | alloc         |
    |               |
--->|i_alloc    i_wr|<---
=N=>|i_data  i_waddr|<=N=
<=N=|o_addr  i_wdata|<=N=
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
    output        [DATA_SZ-1:0] o_addr,                         // allocated address

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

    // aggregate operation pattern
    wire [3:0] curr_op;
    assign curr_op = { i_alloc, i_free, i_rd, i_wr };
    reg [3:0] prev_op;
    initial prev_op = 0;
    always @(posedge i_clk) begin
        prev_op <= curr_op;
    end

    assign o_addr = rdata;
    assign o_rdata = rdata;
//    initial o_addr = UNDEF; <--- not a reg
//    initial o_rdata = UNDEF; <--- not a reg
    initial o_err = 1'b0;

    // an operation for the pointer management port
    wire ptr_op = ((i_alloc || i_free) && !(i_rd || i_wr));

    // an operation for the memory management port
    wire mem_op = (!(i_alloc || i_free) && (i_rd || i_wr));

    // no operation requested
    wire no_op = !(i_alloc || i_free || i_rd || i_wr);

    // top of available memory
    reg [DATA_SZ-1:0] mem_top = (MUT_TAG | VLT_TAG);
    // next value for mem_top (NOTE: extra bit for overflow check)
    wire [ADDR_SZ:0] next_top = { 1'b0, mem_top[ADDR_SZ-1:0] } + 1'b1;

    // next memory cell on free-list
    reg [DATA_SZ-1:0] mem_next = NIL;

    // count of cells on free-list (always non-negative)
    reg [ADDR_SZ-1:0] mem_free = 0;
    // cells are available on the free-list
//    wire free_f = (mem_free == 0);
    wire free_f = mem_next[14];  // check MUT_TAG

    always @(posedge i_clk) begin
//        o_addr <= UNDEF;  // default
//        o_rdata <= UNDEF;  // default prevents block-ram inference
        if (o_err) begin
            // halt in error state...
        end else if (mem_op) begin
            if (i_rd) begin
//                o_rdata <= rdata;  // previously read memory
            end
        end else if (ptr_op) begin
            if (i_alloc && i_free) begin  // assign passed-thru memory
//                o_addr <= i_addr;
            end else if (i_alloc && !free_f) begin  // assign expanded memory
//                o_addr <= mem_top;
                if (next_top[ADDR_SZ]) begin  // overflow check
                    o_err <= 1'b1;  // out-of-memory condition!
                end else begin
                    mem_top <= { mem_top[DATA_SZ-1:ADDR_SZ+1], next_top };
                end
            end else if (i_alloc && free_f) begin  // assign free-list memory
//                o_addr <= mem_next;
                mem_next <= rdata;  // previously read memory
                mem_free <= mem_free - 1'b1;
            end else if (i_free) begin  // link free'd memory into free-list
                mem_next <= i_addr;
                mem_free <= mem_free + 1'b1;
            end
        end else if (no_op) begin
            // nothing to do...
        end else begin
            // conflicting requests
            o_err <= 1'b1;
        end
    end

    wire wr_en = !o_err && ((mem_op && i_wr) || ptr_op);
    wire [7:0] waddr = (
        mem_op
        ? i_waddr[ADDR_SZ-1:0]
        : (
            i_free
            ? i_addr[ADDR_SZ-1:0]
            : (
                free_f
                ? mem_next[ADDR_SZ-1:0]
                : mem_top[ADDR_SZ-1:0]
            )
        )
    );
    wire [15:0] wdata = (
        mem_op
        ? i_wdata
        : (
            (!i_alloc && i_free)
            ? mem_next
            : i_data
        )
    );
    wire rd_en = !o_err && ((mem_op && i_rd) || (ptr_op && free_f));
    wire [7:0] raddr = (
        mem_op
        ? i_raddr[ADDR_SZ-1:0]
        : mem_next[ADDR_SZ-1:0]
    );

    // instantiate bram
    bram BRAM (
        .i_clk(i_clk),
        .i_wr_en(wr_en),
        .i_waddr(waddr),
        .i_wdata(wdata),
        .i_rd_en(rd_en),
        .i_raddr(raddr),
        .o_rdata(rdata)
    );
    wire [15:0] rdata;

endmodule
