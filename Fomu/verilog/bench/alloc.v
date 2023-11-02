/*

Linked-Memory Allocator

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
It has two ports, with two functions each, and a memory-full signal.
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

If o_full is high, the heap is full.
Some memory must be freed before allocation can resume.

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

    input                       i_al,                           // allocation request
    input         [DATA_SZ-1:0] i_adata,                        // initial data
    output reg    [DATA_SZ-1:0] o_aaddr,                        // allocated address

    input                       i_fr,                           // free request
    input         [DATA_SZ-1:0] i_faddr,                        // free address

    input                       i_wr,                           // write request
    input         [DATA_SZ-1:0] i_waddr,                        // write address
    input         [DATA_SZ-1:0] i_wdata,                        // data written

    input                       i_rd,                           // read request
    input         [DATA_SZ-1:0] i_raddr,                        // read address
    output        [DATA_SZ-1:0] o_rdata,                        // data read

    output reg                  o_full                          // memory full condition
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

    assign o_rdata = rdata;
    initial o_full = 1'b0;
    always @(posedge i_clk) begin
        o_full <= (empty_f && full_f);                          // free-list empty, memory full
    end

    // composite signals
    wire al_pass = (i_al && i_fr);                              // pass-thru free+alloc
    wire al_free = (i_al && !i_fr && !empty_f);                 // alloc from free-list
    wire al_top = (i_al && !i_fr && empty_f && !full_f);        // alloc from top-of-memory
    wire fr_free = (!i_al && i_fr);                             // add to free-list

    wire [ADDR_SZ-1:0] al_next = (                              // next address to alloc
        empty_f
        ? mem_top
        : mem_next
    );
    wire [ADDR_SZ-1:0] al_addr = (                              // address allocated
        al_pass
        ? i_faddr[ADDR_SZ-1:0]
        : al_next
    );
    initial o_aaddr = UNDEF;
    always @(posedge i_clk) begin
        // register the allocated address
        o_aaddr <= (MUT_TAG | VLT_TAG | al_addr);
    end

    reg [ADDR_SZ-1:0] mem_top = 0;                              // top of available memory
    reg full_f = 1'b0;                                          // out of memory (hard limit)
    always @(posedge i_clk) begin
        // increment memory top marker
        if (al_top) begin
            {full_f, mem_top} <= {1'b0, mem_top} + 1;
        end
    end

    wire [ADDR_SZ-1:0] mem_next = (                             // next memory cell on free-list
        r_al_free
        ? rdata[ADDR_SZ-1:0]
        : r_mem_next
    );
    reg [ADDR_SZ-1:0] r_mem_next = 0;                           // persistent mem_next value
    reg r_al_free = 1'b0;                                       // previous operation was al_free
    always @(posedge i_clk) begin
        if (fr_free) begin
            // freed cell becomes new free-list head
            r_mem_next <= i_faddr[ADDR_SZ-1:0];
        end else if (r_al_free) begin
            // hang on to the free-list head
            r_mem_next <= rdata[ADDR_SZ-1:0];
        end
        r_al_free <= al_free;
    end

    reg [ADDR_SZ-1:0] mem_free = -1;                            // free-list counter (-1 == empty)
    reg empty_f = 1'b1;                                         // free-list is empty
    always @(posedge i_clk) begin
        if (fr_free) begin
            {empty_f, mem_free} <= {empty_f, mem_free} + 1'b1;
        end else if (al_free) begin
            {empty_f, mem_free} <= {empty_f, mem_free} - 1'b1;
        end
    end

    // instantiate BRAM
    wire wr_en = (i_wr || fr_free || i_al);
    wire [ADDR_SZ-1:0] waddr = (
        i_wr
        ? i_waddr[ADDR_SZ-1:0]
        : (
            fr_free
            ? i_faddr[ADDR_SZ-1:0]
            : al_addr
        )
    );
    wire [DATA_SZ-1:0] wdata = (
        i_wr
        ? i_wdata
        : (
            fr_free
            ? mem_next
            : i_adata
        )
    );
    wire rd_en = (i_rd || al_free);
    wire [ADDR_SZ-1:0] raddr = (
        i_rd
        ? i_raddr[ADDR_SZ-1:0]
        : mem_next
    );
    wire [DATA_SZ-1:0] rdata;  // data read from BRAM
    bram BRAM (
        .i_clk(i_clk),
        .i_wr_en(wr_en),
        .i_waddr(waddr),
        .i_wdata(wdata),
        .i_rd_en(rd_en),
        .i_raddr(raddr),
        .o_rdata(rdata)
    );

endmodule
