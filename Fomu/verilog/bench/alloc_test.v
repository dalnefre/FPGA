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
`include "alloc.james.v"

module alloc_test (
    input                       i_clk,                          // system clock
    input                       i_en,                           // testing enabled
    output                      o_running,
    output reg           [15:0] o_debug,
    output                      o_passed,
    output                      o_error
);
    localparam ADDR_SZ = 4;//8;  // must be at least 3
    localparam UNDEF = 16'h0000;
    localparam NIL = 16'h0001;

// Whilst 'i_en' is high, the sequence counter increments each clock cycle
// until the test is concluded.

// Bits [ADDR_SZ-1:0] correspond to a cell count.
// Bits [ADDR_SZ+1] and [ADDR_SZ] indicate the current phase of operation:

//  00... Memory is being allocated.
//  01... Memory is being read.
//  10... The test has finished and a report is being generated.
//  11... The test rig has halted. The report is encoded in the low bits.

// The reports bits are as follows:

//  seq[0]  err
//  seq[1]  pass

    reg [ADDR_SZ+1:0] seq = 0;
    wire allocating = !seq[ADDR_SZ+1] && !seq[ADDR_SZ] && i_en;
    wire reading =    !seq[ADDR_SZ+1] &&  seq[ADDR_SZ] && i_en;
    wire done =        seq[ADDR_SZ+1] && !seq[ADDR_SZ];
    wire halted =      seq[ADDR_SZ+1] &&  seq[ADDR_SZ];
    assign o_running = !halted;
    initial o_debug = UNDEF;
    assign o_passed = halted && seq[1];
    assign o_error = halted && seq[0];

// The 'addr_rdy' and 'rdata_rdy' registers are high in cycles immediately
// following an allocation or read operation.

    reg addr_rdy = 0;
    reg rdata_rdy = 0;
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
            seq <= (3 << ADDR_SZ) | 2'b01; // halt with error
        end else if (done) begin
            seq <= (3 << ADDR_SZ) | (
                (rdata == NIL)
                ? 2'b10 // pass with no error
                : 2'b00 // fail with no error
            );
            o_debug <= rdata;
        end else if (allocating || reading) begin
            // FIXME: are rdata/addr lost if i_en goes low?
            seq <= seq + 1'b1;
        end
    end
endmodule
