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

This component tests alloc.v, producing a pass or fail result.

Activity is paused until i_en goes low. During operation, o_running remains
high. Once o_running goes low, the value of o_pass indicates success or failure.

The four kinds of allocator requests are tested, including ALLOCATE, FREE, READ,
and WRITE. Simultaneous READ and WRITE requests are tested, but not ALLOCATE
and FREE requests.

Additionally, the memory is completely filled and emptied twice.

Each of the two test runs has three distinct phases:

 PHASE 1
     Cells are continually allocated to form a linked list ending with NIL.
     The number of cells allocated is 2^ADDR_SZ.

 PHASE 2
     The linked list is reversed in situ by use of simultaneous read and write
     requests.

 PHASE 3
     The reversed list is traversed, with each cell being freed after it is
     read. Note that phase 3 takes twice as long as either phase 1 or phase
     2, because concurrent read and free requests are not permitted.

The test fails if the allocator reports an error at any time. It succeeds
only if the linked list was the expected length and terminated in NIL.

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
    localparam ADDR_SZ = 8;  // must be at least 2
    localparam UNDEF = 16'h0000;
    localparam NIL = 16'h0001;

// Whilst 'i_en' is high, the state vector increments each clock cycle until the
// test is concluded.

    reg [ADDR_SZ+4:0] state = 0;
    initial o_debug = UNDEF;

// state[ADDR_SZ+4]
//      Indicates that the test has concluded, with a report encoded in the low
//      bits:

//          state[0] Indicates the test passed.
//          state[1] Indicates the allocator raised an error signal.

    wire done = state[ADDR_SZ+4];
    assign o_running = !done;
    assign o_passed = done && state[0];
    assign o_error = done && state[1];

// state[ADDR_SZ+3]
//      Indicates that the test has just finished and a report is being
//      generated.

    wire check = state[ADDR_SZ+3];

// state[ADDR_SZ+2]
//      0) First run. Allocations raise the top of memory.
//      1) Second run. Allocations are made from the free list.

// state[ADDR_SZ+1]
//      0) Build up phase. A linked list is allocated and reversed in place.
//          state[ADDR_SZ]
//               0) Allocate a cell.
//               1) Reverse an element using a simultaneous read+write.

//      1) Tear down phase. The linked list is followed and freed.
//          state[0]
//              0) Read a cell.
//              1) Free that cell.

    wire incrementing = i_en && !done && !check;
    wire build_up = incrementing && !state[ADDR_SZ+1];
    wire allocate = incrementing &&  build_up && !state[ADDR_SZ];
    wire reverse =  incrementing &&  build_up &&  state[ADDR_SZ];
    wire read =     incrementing && !build_up && !state[0];
    wire free =     incrementing && !build_up &&  state[0];

// state[ADDR_SZ-1:0]   (during build up)
// state[ADDR_SZ:1]     (during tear down)
//      Counts the cells in the linked list. Note that the location of this
//      vector shifts one bit to the left during the tear down phase, but does
//      not change size.

    reg addr_rdy = 0;
    reg addr_prev_rdy = 0;
    reg rdata_rdy = 0;
    reg rdata_prev_rdy = 0;
    reg [15:0] addr_prev = UNDEF;
    reg [15:0] rdata_prev = UNDEF;
    reg [15:0] rdata_prev_prev = UNDEF;
    always @(posedge i_clk) begin
        if (i_en) begin
            addr_rdy <= allocate;
            rdata_rdy <= read || reverse;
            addr_prev <= addr;
            addr_prev_rdy <= addr_rdy;
            rdata_prev <= rdata;
            rdata_prev_rdy <= rdata_rdy;
            rdata_prev_prev <= rdata_prev;
        end
    end
    wire        err;
    wire [15:0] addr;
    wire [15:0] rdata;
    alloc #(
        .ADDR_SZ(8)
    ) ALLOC (
        .i_clk(i_clk),
        .i_alloc(allocate),
        .i_data(
            addr_rdy
            ? addr
            : NIL
        ),
        .o_addr(addr),
        .i_free(free),
        .i_addr(
            free
            ? rdata_prev_prev
            : UNDEF
        ),
        .i_wr(reverse),
        .i_waddr(
            rdata_rdy
            ? rdata
            : addr
        ),
        .i_wdata(
            rdata_prev_rdy
            ? rdata_prev
            : (
                (addr_prev_rdy && !addr_rdy)
                ? addr_prev
                : NIL
            )
        ),
        .i_rd(reverse || read),
        .i_raddr(
            read
            ? rdata_prev
            : (
                reverse
                ? (
                    rdata_rdy
                    ? rdata
                    : addr
                )
                : UNDEF
            )
        ),
        .o_rdata(rdata),
        .o_err(err)
    );
    always @(posedge i_clk) begin
        if (i_en) begin
            if (err) begin
                state <= (1 << (ADDR_SZ+4)) | 2'b10; // halt with error
            end else if (check) begin
                state <= (1 << (ADDR_SZ+4)) | (
                    (rdata_prev == NIL)
                    ? 2'b01 // pass with no error
                    : 2'b00 // fail with no error
                );
                o_debug <= rdata;
            end else if (!done && !check) begin
                // FIXME: are rdata/addr lost if i_en goes low?
                state <= state + 1'b1;
            end
        end
    end
endmodule
