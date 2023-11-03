/*

Test component for the quad allocator

    +---------------+
    | alloc_test    |
    |               |
--->|i_en  o_running|--->
    |        o_debug|--->
    |       o_passed|--->
    |               |
 +->|i_clk          |
 |  +---------------+

Activity is paused until i_en goes low. During operation, o_running remains
high. Once o_running goes low, the value of o_pass indicates success or failure.

All four kinds of allocator requests are tested, including ALLOCATE, FREE, READ,
and WRITE. Simultaneous READ and WRITE requests are tested, but not
simultaneous ALLOCATE and FREE requests.

The memory is completely filled and emptied twice, to ensure correct operation
of the free list. Each of the two test runs has three distinct phases:

PHASE 1

    addresses     0       1       2             252     253     254     255
                +---+   +---+   +---+          +---+   +---+   +---+   +---+
    quads       |NIL|<--+-0 |<--+-1 |  ...  <--+251|<--+252|<--+253|<--+254|
                +---+   +---+   +---+          +---+   +---+   +---+   +---+
    requests      A  ->   A  ->   A    ...       A  ->   A  ->   A  ->   A

    DICT_T quads are allocated to form a linked list ending in NIL, completely
    filling the allocator's memory.

PHASE 2

    addresses                   250     251     252     253     254     255
                               +---+   +---+   +---+   +---+   +---+   +---+
    quads              ...  <--+249|<--+250|   |253+-->|254+-->|255+-->|NIL|
                               +---+   +---+   +---+   +---+   +---+   +---+
    requests                                    R+W  <- R+W  <- R+W  <- R+W

    The linked list is reversed, in situ, using simultaneous read and write
    requests.

PHASE 3

    addresses     0       1             251     252     253     254     255
                +---+   +---+          +---+   +---+   +---+   +---+   +---+
    quads       |   |   |   |   ...    |   |   |   |   |254+-->|255+-->|NIL|
                +---+   +---+          +---+   +---+   +---+   +---+   +---+
    requests     R,F ->  R,F    ...     R,F ->  R,F

    The reversed list is traversed, with each quad being freed after it is read.
    Note that phase 3 takes twice as long as either phase 1 or phase 2, because
    concurrent read and free requests are not permitted.

The test succeeds only if the traversed linked list was the expected length and
terminated in NIL.

*/

`default_nettype none

`include "alloc.james.v"
// `include "alloc.v"

module alloc_test (
    input                       i_clk,                  // system clock
    input                       i_en,                   // testing enabled
    output                      o_running,
    output reg  [QUAD_SZ-1:0]   o_debug,
    output reg                  o_passed
);

// To synthesize correctly, ADDR_SZ and BLK_DATA_SZ must be chosen such that
// BLK_DATA_SZ * 2^ADDR_SZ = 4096.

    localparam ADDR_SZ = 10;  // must be at least 2
    localparam FIELD_SZ = 16;
    localparam QUAD_SZ = 4 * FIELD_SZ;
    localparam BLK_DATA_SZ = 4; // 8 blocks
    localparam UNDEF = 1'b0;
    localparam NIL = 1'b1;
    localparam DICT_T = 13; // 0xD
    localparam DICT_QUAD = DICT_T << (3 * FIELD_SZ);

// The 'done' register indicates that the test has concluded.

    reg done = 0;

// Whilst 'i_en' is high, the 'state' vector increments each clock cycle until
// the test finishes.

    reg [ADDR_SZ+3:0] state = 0;
    always @(posedge i_clk) begin
        if (i_en) begin
            state <= state + 1;
        end
    end

// state[ADDR_SZ+3]
//      Indicates that the test has just finished and a report is being
//      generated.

    reg check = 0;
    always @(posedge i_clk) begin
        check <= i_en && state[ADDR_SZ+3] && !done && !check;
    end

// state[ADDR_SZ+2]
//      0) First run. Allocations raise the top of memory.
//      1) Second run. Allocations are made from the free list.

// state[ADDR_SZ+1]
//      0) Build up phase. A linked list is allocated and reversed in place.
//         The state[ADDR_SZ] bit controls whether the list is being allocated
//         or reversed.
//      1) Tear down phase. The linked list is followed and freed. The state[0]
//         bit controls whether the current quad is being read or freed.

// The signals provided to the allocator are delayed a cycle,
// so that the combinatorial logic dependent on 'state' has time to settle.

    reg allocate = 0;
    reg reverse = 0;
    reg read = 0;
    reg free = 0;
    wire working =  i_en && !done && !state[ADDR_SZ+3];
    always @(posedge i_clk) begin
        allocate <= working && !state[ADDR_SZ+1] && !state[ADDR_SZ];
        reverse  <= working && !state[ADDR_SZ+1] &&  state[ADDR_SZ];
        read     <= working &&  state[ADDR_SZ+1] && !state[0];
        free     <= working &&  state[ADDR_SZ+1] &&  state[0];
    end

// state[ADDR_SZ-1:0]   (during build up)
// state[ADDR_SZ:1]     (during tear down)
//      Counts the quads in the linked list. Note that the location of this
//      vector shifts one bit to the left during the tear down phase, but does
//      not change size.

// The following registers provide the working memory necessary to perform
// the list operations.

    reg addr_rdy = 0;
    reg rdata_rdy = 0;
    reg rdata_prev_rdy = 0;
    reg second_write = 0;
    reg [FIELD_SZ-1:0] addr_prev = UNDEF;
    reg [QUAD_SZ-1:0] rdata_prev = -1;
    reg [QUAD_SZ-1:0] rdata_prev_prev = -1;
    always @(posedge i_clk) begin
        if (i_en) begin
            addr_rdy <= allocate;
            rdata_rdy <= read || reverse;
            addr_prev <= addr;
            rdata_prev <= rdata;
            rdata_prev_rdy <= rdata_rdy;
            rdata_prev_prev <= rdata_prev;
            second_write <= addr_rdy && !allocate;
        end
    end
    wire [FIELD_SZ-1:0] addr;
    wire [QUAD_SZ-1:0] rdata;
    wire [QUAD_SZ-1:0] addr_quad = DICT_QUAD | addr; // [DICT_T, #?, #?, addr]
    alloc #(
        .ADDR_SZ(ADDR_SZ),
        .FIELD_SZ(FIELD_SZ),
        .BLK_DATA_SZ(BLK_DATA_SZ)
    ) ALLOC (
        .i_clk(i_clk),
        .i_al(allocate),
        .i_adata(
            addr_rdy
            ? addr_quad
            : (DICT_QUAD | NIL)
        ),
        .o_aaddr(addr),
        .i_fr(free),
        .i_faddr(rdata_prev_prev[FIELD_SZ-1:0]),
        .i_wr(reverse),
        .i_waddr(
            rdata_rdy
            ? rdata[FIELD_SZ-1:0]
            : addr
        ),
        .i_wdata(
            rdata_prev_rdy
            ? rdata_prev
            : (
                second_write
                ? (DICT_QUAD | addr_prev)
                : (DICT_QUAD | NIL) // first write
            )
        ),
        .i_rd(reverse || read),
        .i_raddr(
            read
            ? rdata_prev[FIELD_SZ-1:0]
            : (
                rdata_rdy
                ? rdata[FIELD_SZ-1:0]
                : addr
            )
        ),
        .o_rdata(rdata)
    );
    assign o_running = i_en && !done;
    initial o_passed = 0;
    initial o_debug = -1;
    always @(posedge i_clk) begin
        if (check) begin
            done <= 1;
            o_passed <= (
                rdata_prev == (DICT_QUAD | NIL)
                ? 1 // pass
                : 0 // fail
            );
            o_debug <= rdata_prev;
        end
    end
endmodule
