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
    localparam BASE             = 16'h5000;                     // offset 0 into RAM

    assign o_running = i_en && (state != 0);

    initial o_debug = UNDEF;
    initial o_passed = 1'b0;
    initial o_error = 1'b0;

    reg [7:0] state;  // 8-bit state-machine
    initial state = 1;

    // inputs
    wire al_en;
    wire [15:0] adata;
    wire fr_en;
    wire [15:0] faddr;
    wire wr_en;
    wire [15:0] waddr;
    wire [15:0] wdata;
    wire rd_en;
    wire [15:0] raddr;
    // outputs
    wire [15:0] aaddr;
    wire [15:0] rdata;
    wire err;
    alloc ALLOC (
        .i_clk(i_clk),

        .i_alloc(al_en),
        .i_data(adata),
        .o_addr(aaddr),

        .i_free(fr_en),
        .i_addr(faddr),

        .i_wr(wr_en),
        .i_waddr(waddr),
        .i_wdata(wdata),

        .i_rd(rd_en),
        .i_raddr(raddr),
        .o_rdata(rdata),

        .o_err(err)
    );

    assign al_en = ((state == 8)
        || (state == 10) || (state == 11) || (state == 12)
        || (state == 17) || (state == 18) || (state == 19));
    assign adata =
        (state == 8)
        ? (ZERO | 21)
        : (
            (state == 10)
            ? (ZERO | 256)
            : (
                (state == 11)
                ? (ZERO | 257)
                : (
                    (state == 12)
                    ? (ZERO | 258)
                    : (
                        (state == 17)
                        ? (ZERO | 259)
                        : (
                            (state == 18)
                            ? (ZERO | 260)
                            : (
                                (state == 19)
                                ? (ZERO | 261)
                                : UNDEF
                            )
                        )
                    )
                )
            )
        );
    assign fr_en = ((state == 15) || (state == 16) || (state == 18));
    assign faddr =
        (state == 15)
        ? (BASE | 2)
        : (
            (state == 16)
            ? (BASE | 1)
            : (
                (state == 18)
                ? (BASE | 0)
                : UNDEF
            )
        );
    assign rd_en = ((state == 4) || (state == 5) || (state == 8));
    assign raddr =
        (state == 4)
        ? (BASE | 42)
        : (
            (state == 5)
            ? (BASE | 144)
            : (
                (state == 8)
                ? (BASE | 13)
                : UNDEF
            )
        );
    assign wr_en = ((state == 2) || (state == 3));
    assign waddr =
        (state == 2)
        ? (BASE | 42)
        : (
            (state == 3)
            ? (BASE | 144)
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
        if (o_running) begin
            o_error <= err;
            state <= err ? 0 : state + 1'b1;  // default: advance to next state or fail
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
                8: begin
                    // read/alloc conflict
                    // rdata <= ram[13];
                    // aaddr <= alloc(21);
                end
                9: begin
                    // assert(err)
                    if (err) begin
                        o_error <= 1'b0;
                        state <= 10;
                    end else begin
                        state <= 0;
                    end
                end
                10: begin
                    // aaddr <= alloc(256);
                end
                11: begin
                    // assert(aaddr == ^5..0)
                    if (aaddr != (BASE | 0)) begin
                        o_debug <= aaddr;
                        state <= 0;
                    end
                    // aaddr <= alloc(257);
                end
                12: begin
                    // assert(aaddr == ^5..1)
                    if (aaddr != (BASE | 1)) begin
                        o_debug <= aaddr;
                        state <= 0;
                    end
                    // aaddr <= alloc(258);
                end
                13: begin
                    // assert(aaddr == ^5..2)
                    if (aaddr != (BASE | 2)) begin
                        o_debug <= aaddr;
                        state <= 0;
                    end
                end
                15: begin
                    // free(^5..2);
                end
                16: begin
                    // free(^5..1);
                end
                17: begin
                    // aaddr <= alloc(259);
                end
                18: begin
                    // assert(aaddr == ^5..1)
                    if (aaddr != (BASE | 1)) begin
                        o_debug <= aaddr;
                        state <= 0;
                    end
                    // free(^5..0);
                    // aaddr <= alloc(260);
                end
                19: begin
                    // assert(aaddr == ^5..0)
                    if (aaddr != (BASE | 0)) begin
                        o_debug <= aaddr;
                        state <= 0;
                    end
                    // aaddr <= alloc(261);
                end
                20: begin
                    // assert(aaddr == ^5..2)
                    if (aaddr != (BASE | 2)) begin
                        o_debug <= aaddr;
                        state <= 0;
                    end
                end
                25: begin
                    // successful completion
                    o_passed <= 1'b1;
                    state <= 0;
                end
            endcase
        end
    end

endmodule
