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
    output reg    [DATA_SZ-1:0] o_rdata,                        // data read

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
    initial o_rdata = UNDEF;
    initial o_err = 1'b0;

    wire ptr_op;                // an operation for the pointer management port
    assign ptr_op = ((i_alloc || i_free) && !(i_rd || i_wr));

    wire mem_op;                // an operation for the memory management port
    assign mem_op = (!(i_alloc || i_free) && (i_rd || i_wr));

    wire no_op;                 // no operation requested
    assign no_op = !(i_alloc || i_free || i_rd || i_wr);

    // top of available memory
    reg [DATA_SZ-1:0] mem_top;
    initial mem_top = (MUT_TAG | VLT_TAG);
    wire [ADDR_SZ:0] next_top;  // NOTE: extra bit for overflow check
    assign next_top = { 1'b0, mem_top[ADDR_SZ-1:0] } + 1'b1;

    // next memory cell on free-list
    reg [DATA_SZ-1:0] mem_next;
    initial mem_next = NIL;
    wire free_f;                // cells are available on the free-list
    assign free_f = mem_next[14];  // check MUT_TAG

    // count of cells on free-list (always non-negative)
    reg [DATA_SZ-1:0] mem_free;
    initial mem_free = ZERO;  // NOTE: encoded as a fixnum

    always @(posedge i_clk) begin
        if (o_err) begin
            o_err <= 1'b1;
        end else if (ptr_op) begin
            if (i_alloc && i_free) begin
                ram_cell[i_addr[ADDR_SZ-1:0]] <= i_data;  // assign passed-thru memory
                o_addr <= i_addr;
            end else if (i_alloc && free_f) begin
                ram_cell[mem_next[ADDR_SZ-1:0]] <= i_data;  // assign free-list memory
                o_addr <= mem_next;
                mem_next <= ram_cell[mem_next[ADDR_SZ-1:0]];
                mem_free <= mem_free - 1'b1;
            end else if (i_alloc) begin
                ram_cell[mem_top[ADDR_SZ-1:0]] <= i_data;  // assign expanded memory
                o_addr <= mem_top;
                if (next_top[ADDR_SZ]) begin  // overflow check
                    o_err <= 1'b1;  // out-of-memory condition!
                end else begin
                    mem_top <= { mem_top[DATA_SZ-1:ADDR_SZ+1], next_top };
                end
            end else if (i_free) begin
                ram_cell[i_addr[ADDR_SZ-1:0]] <= mem_next;  // link free'd memory into free-list
                o_addr <= UNDEF;
                mem_next <= i_addr;
                mem_free <= mem_free + 1'b1;
            end
        end else if (mem_op) begin
            if (i_wr) begin
                ram_cell[i_waddr[ADDR_SZ-1:0]] <= i_wdata;  // write memory
            end
            if (i_rd) begin
                o_rdata <= ram_cell[i_raddr[ADDR_SZ-1:0]];  // read memory
            end
        end else if (no_op) begin
            o_err <= 1'b0;
        end else begin
            // conflicting requests
            o_err <= 1'b1;
        end
    end

    // dynamically managed memory
    reg [DATA_SZ-1:0] ram_cell [0:MEM_MAX-1];
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

endmodule
