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

All four kinds of allocator request are tested, including ALLOCATE, FREE, READ,
and WRITE. Simultaneous READ and WRITE requests are tested, but not
simultaneous ALLOCATE and FREE requests.

The memory is completely filled and emptied twice, to ensure correct operation
of the free list. Each of the two test runs has three distinct phases:

PHASE 1

    address       0       1       2             252     253     254     255
                +---+   +---+   +---+          +---+   +---+   +---+   +---+
    cell        |NIL|<--+-0 |<--+-1 |  ...  <--+251|<--+252|<--+253|<--+254|
                +---+   +---+   +---+          +---+   +---+   +---+   +---+
    request       A  ->   A  ->   A    ...       A  ->   A  ->   A  ->   A

    Cells are allocated to form a linked list ending in NIL, completely filling
    the allocator's memory.

PHASE 2

    address                     250     251     252     253     254     255
                               +---+   +---+   +---+   +---+   +---+   +---+
    cell               ...  <--+249|<--+250|   |253+-->|254+-->|255+-->|NIL|
                               +---+   +---+   +---+   +---+   +---+   +---+
    request                                     R+W  <- R+W  <- R+W  <- R+W

    The linked list is reversed, in situ, using simultaneous read and write
    requests.

PHASE 3

    address       0       1             251     252     253     254     255
                +---+   +---+          +---+   +---+   +---+   +---+   +---+
    cell        |   |   |   |   ...    |   |   |   |   |254+-->|255+-->|NIL|
                +---+   +---+          +---+   +---+   +---+   +---+   +---+
    request      R,F ->  R,F    ...     R,F ->  R,F

    The reversed list is traversed, with each cell being freed after it is read.
    Note that phase 3 takes twice as long as either phase 1 or phase 2, because
    concurrent read and free requests are not permitted.

The test fails if the allocator reports an error at any time. It succeeds only
if the traversed linked list was the expected length and terminated in NIL.

*/

`default_nettype none

// `define ALLOC_TEST_MUX

`ifdef ALLOC_TEST_MUX
`include "alloc_mux.v"
`else
`include "alloc.james.v"
// `include "alloc.v"
`endif

module alloc_test (
    input                       i_clk,                          // system clock
    input                       i_en,                           // testing enabled
    output                      o_running,
    output reg           [15:0] o_debug,
    output                      o_passed,
    output                      o_error
);
`ifdef ALLOC_TEST_MUX
    localparam ADDR_SZ = 12;  // must be at least 2
`else
    localparam ADDR_SZ = 8;  // must be at least 2
`endif
    localparam UNDEF = 16'h0000;
    localparam NIL = 16'h0001;

// Whilst 'i_en' is high, the 'state' vector increments each clock cycle until
// the test finishes.

    reg [ADDR_SZ+4:0] state = 0;

// state[ADDR_SZ+4]
//      Indicates that the test has concluded, with a report encoded in the low
//      two bits.

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
//         The state[ADDR_SZ] bit controls whether the list is being allocated
//         or reversed.
//      1) Tear down phase. The linked list is followed and freed. The state[0]
//         bit controls whether the current cell is being read or freed.

    wire working = i_en && !done && !check;
    wire build_up = working && !state[ADDR_SZ+1];
    wire allocate = working &&  build_up && !state[ADDR_SZ];
    wire reverse =  working &&  build_up &&  state[ADDR_SZ];
    wire read =     working && !build_up && !state[0];
    wire free =     working && !build_up &&  state[0];

// state[ADDR_SZ-1:0]   (during build up)
// state[ADDR_SZ:1]     (during tear down)
//      Counts the cells in the linked list. Note that the location of this
//      vector shifts one bit to the left during the tear down phase, but does
//      not change size.

// The following registers provide the working memory necessary to perform
// the list operations.

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
`ifdef ALLOC_TEST_MUX
    alloc_mux #(
`else
    alloc #(
`endif
        .ADDR_SZ(ADDR_SZ)
    ) ALLOC (
        .i_clk(i_clk),
        .i_al(allocate),
        .i_adata(
            addr_rdy
            ? addr
            : NIL
        ),
        .o_aaddr(addr),
        .i_fr(free),
        .i_faddr(
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
    initial o_debug = UNDEF;
    always @(posedge i_clk) begin
        if (i_en) begin
            if (err) begin
                state <= (1 << (ADDR_SZ+4)) | 2'b10; // halt with error
            end else if (check) begin
                state <= (1 << (ADDR_SZ+4)) | (
                    rdata_prev == NIL
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
