/*

Test fixture for the Linked-Memory Allocator

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
high. Once o_running goes low, the value of o_passed indicates success or failure.
If the allocator signals o_err, then o_error is held high (sticky).

*/

`default_nettype none

`include "alloc.v"

module alloc_test (
    input                       i_clk,                          // system clock
    input                       i_en,                           // testing enabled
    output                      o_running,
    output reg           [15:0] o_debug,
    output reg                  o_passed,
    output reg                  o_error
);
    // reserved constants
    localparam UNDEF            = 16'h0000;                     // undefined value
    localparam NIL              = 16'h0001;                     // the empty list
    localparam TRUE             = 16'h0002;                     // boolean true
    localparam FALSE            = 16'h0003;                     // boolean false
    localparam UNIT             = 16'h0004;                     // inert result
    localparam ZERO             = 16'h8000;                     // fixnum +0
    localparam RAM_BASE         = 16'h5000;                     // offset 0 into RAM

    assign o_running = i_en && (state != 0);

    initial o_debug = UNDEF;
    initial o_passed = 1'b0;
    initial o_error = 1'b0;

    reg [7:0] state;  // 8-bit state-machine
    initial state = 1;

    // inputs
    wire alloc;
    wire free;
    wire wr_en;
    wire [15:0] waddr;
    wire [15:0] wdata;
    wire rd_en;
    // outputs
    wire [15:0] raddr;
    wire [15:0] rdata;
    wire err;
    alloc ALLOC (
        .i_clk(i_clk),

        .i_alloc(alloc),
        .i_data(wdata),
        .o_addr(raddr),

        .i_free(free),
        .i_addr(waddr),

        .i_wr(wr_en),
        .i_waddr(waddr),
        .i_wdata(wdata),

        .i_rd(rd_en),
        .i_raddr(waddr),
        .o_rdata(rdata),

        .o_err(err)
    );

    assign alloc = (state == 10);
    assign free = (state == 20);
    assign wr_en = ((state == 2) || (state == 3));
    assign rd_en = ((state == 4) || (state == 5));
    assign waddr =
        ((state == 2) || (state == 4))
        ? (RAM_BASE | 42)
        : (
            ((state == 3) || (state == 5))
            ? (RAM_BASE | 144)
            : UNDEF
        );
    assign wdata =
        (state == 2)
        ? (ZERO | 420)
        : (
            (state == 3)
            ? (ZERO | 1337)
            : UNDEF
        );

    always @(posedge i_clk) begin
        if (err) begin
            o_error <= 1'b1;
            state <= 0;
        end else if (o_running) begin
            state <= state + 1'b1;  // default: advance to next state
            case (state)
                1: begin
                    // start state
                end
                2: begin
                    // ram[42] <= 420
                end
                3: begin
                    // ram[144] <= 1337
                end
                4: begin
                    // rdata <= ram[42]
                end
                5: begin
                    // assert(rdata == 420)
                    if (rdata != (ZERO | 420)) begin
                        o_debug <= rdata;
                        state <= 0;
                    end
                    // rdata <= ram[144]
                end
                6: begin
                    // assert(rdata == 1337)
                    if (rdata != (ZERO | 1337)) begin
                        o_debug <= rdata;
                        state <= 0;
                    end
                end
                9: begin
                    // successful completion
                    o_passed <= 1'b1;
                    state <= 0;
                end
            endcase
        end
    end

endmodule
