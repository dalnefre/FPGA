/*

Test component for the Linked-Memory Allocator

    +---------------+
    | alloc_test    |
    |               |
--->|i_en  o_running|--->
    |        o_debug|--->
    |       o_passed|--->
    |        o_error|--->
    |               |
 +->|i_clk          |
 |  +---------------+

This component runs some tests on alloc.v, producing a pass or fail result.
Activity is paused whilst i_en is low. During operation, o_running remains
high. Once o_running goes low, the value of o_pass indicates success or failure.

*/

`default_nettype none
`include "alloc.v"

module alloc_test (
    input                       i_clk,                          // system clock
    input                       i_en,                           // testing enabled
    output                      o_running,
    output reg           [15:0] o_debug,
    output                      o_passed,
    output                      o_error
);
    localparam ADDR_SZ = 4;//8;  // must be at least 3
    localparam NIL = 16'h0001;

    assign o_running = !halted;
    initial o_debug = 0;  // UNDEF
    assign o_passed = halted && seq[1];
    assign o_error = halted && seq[0];

// Whilst 'i_en' is high, the sequence counter increments every clock cycle
// until the test is concluded.

// Bits [ADDR_SZ-1:0] correspond to a cell count.
// Bits [ADDR_SZ] and [ADDR_SZ+1] indicate the current phase of operation:

//  00... Memory is being allocated.
//  01... Memory is being read.
//  10... The test has concluded.
//  11... The test rig has halted.

    reg [ADDR_SZ+1:0] seq;
    initial seq = 0;
    wire allocating;
    assign allocating = i_en && !seq[ADDR_SZ+1] && !seq[ADDR_SZ];
    wire reading;
    assign reading = i_en && !seq[ADDR_SZ+1] && seq[ADDR_SZ];
    wire done;
    assign done = seq[ADDR_SZ+1] && !seq[ADDR_SZ];
    wire halted;
    assign halted = seq[ADDR_SZ+1] && seq[ADDR_SZ];

// The 'addr_rdy' and 'rdata_rdy' registers are high in cycles immediately
// following an allocation or read operation.

    reg addr_rdy;
    initial addr_rdy = 0;
    reg rdata_rdy;
    initial rdata_rdy = 0;
    always @(posedge i_clk) begin
        addr_rdy <= allocating;
        rdata_rdy <= reading;
    end

// During phase 1, cells are continually allocated to form a linked list ending
// with NIL. At the moment the linked list completely fills memory, phase 2
// begins. The linked list is then followed to its terminal value, which should
// be NIL.

// The test fails if the allocator reports an error at any time. It succeeds if
// the linked list was the expected length and terminated in NIL.

    wire        err;
    wire [15:0] addr;
    wire [15:0] rdata;
    alloc #(
        .ADDR_SZ(8)
    ) ALLOC (
        .i_clk(i_clk),
        .i_alloc(allocating),
        .i_data(
            addr_rdy
            ? addr
            : NIL
        ),
        .o_addr(addr),
        .i_free(1'b0),
        .i_addr(16'b0),
        .i_wr(1'b0),
        .i_waddr(16'b0),
        .i_wdata(16'b0),
        .i_rd(reading),
        .i_raddr(
            rdata_rdy
            ? rdata
            : addr
        ),
        .o_rdata(rdata),
        .o_err(err)
    );
    always @(posedge i_clk) begin
        if (err) begin
            seq <= (16'b11 << ADDR_SZ) | 3'b001;
        end else if (done) begin
            seq <= (16'b11 << ADDR_SZ) | ((rdata == NIL) ? 3'b010 : 3'b000);
            o_debug <= rdata;
        end else if (allocating || reading) begin
            seq <= seq + 1'b1;
        end
    end
endmodule
