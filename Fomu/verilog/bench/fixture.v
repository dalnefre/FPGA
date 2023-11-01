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
//`include "alloc.james.v"

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

    reg [4:0] state;  // 5-bit state-machine
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

        .i_al(al_en),
        .i_adata(adata),
        .o_aaddr(aaddr),

        .i_fr(fr_en),
        .i_faddr(faddr),

        .i_wr(wr_en),
        .i_waddr(waddr),
        .i_wdata(wdata),

        .i_rd(rd_en),
        .i_raddr(raddr),
        .o_rdata(rdata),

        .o_err(err)
    );

    reg [16:0] al_mem [0:31];
    initial begin
        al_mem[0] = {1'b0, UNDEF};
        al_mem[1] = {1'b0, UNDEF};
        al_mem[2] = {1'b0, UNDEF};
        al_mem[3] = {1'b0, UNDEF};
        al_mem[4] = {1'b0, UNDEF};
        al_mem[5] = {1'b0, UNDEF};
        al_mem[6] = {1'b0, UNDEF};
        al_mem[7] = {1'b0, UNDEF};
        al_mem[8] = {1'b0, UNDEF};
        al_mem[9] = {1'b0, UNDEF};
        al_mem[10] = {1'b1, (ZERO | 16'd256)};
        al_mem[11] = {1'b1, (ZERO | 16'd257)};
        al_mem[12] = {1'b1, (ZERO | 16'd258)};
        al_mem[13] = {1'b0, UNDEF};
        al_mem[14] = {1'b0, UNDEF};
        al_mem[15] = {1'b0, UNDEF};
        al_mem[16] = {1'b0, UNDEF};
        al_mem[17] = {1'b1, (ZERO | 16'd259)};
        al_mem[18] = {1'b1, (ZERO | 16'd260)};
        al_mem[19] = {1'b1, (ZERO | 16'd261)};
        al_mem[20] = {1'b0, UNDEF};
        al_mem[21] = {1'b0, UNDEF};
        al_mem[22] = {1'b0, UNDEF};
        al_mem[23] = {1'b0, UNDEF};
        al_mem[24] = {1'b0, UNDEF};
        al_mem[25] = {1'b0, UNDEF};
        al_mem[26] = {1'b0, UNDEF};
        al_mem[27] = {1'b0, UNDEF};
        al_mem[28] = {1'b0, UNDEF};
        al_mem[29] = {1'b0, UNDEF};
        al_mem[30] = {1'b0, UNDEF};
        al_mem[31] = {1'b0, UNDEF};
    end
    assign al_en = al_mem[state][16];
    assign adata = al_mem[state][15:0];

    reg [16:0] fr_mem [0:31];
    initial begin
        fr_mem[0] = {1'b0, UNDEF};
        fr_mem[1] = {1'b0, UNDEF};
        fr_mem[2] = {1'b0, UNDEF};
        fr_mem[3] = {1'b0, UNDEF};
        fr_mem[4] = {1'b0, UNDEF};
        fr_mem[5] = {1'b0, UNDEF};
        fr_mem[6] = {1'b0, UNDEF};
        fr_mem[7] = {1'b0, UNDEF};
        fr_mem[8] = {1'b0, UNDEF};
        fr_mem[9] = {1'b0, UNDEF};
        fr_mem[10] = {1'b0, UNDEF};
        fr_mem[11] = {1'b0, UNDEF};
        fr_mem[12] = {1'b0, UNDEF};
        fr_mem[13] = {1'b0, UNDEF};
        fr_mem[14] = {1'b0, UNDEF};
        fr_mem[15] = {1'b1, (BASE | 16'd2)};
        fr_mem[16] = {1'b1, (BASE | 16'd1)};
        fr_mem[17] = {1'b0, UNDEF};
        fr_mem[18] = {1'b1, (BASE | 16'd0)};
        fr_mem[19] = {1'b0, UNDEF};
        fr_mem[20] = {1'b0, UNDEF};
        fr_mem[21] = {1'b0, UNDEF};
        fr_mem[22] = {1'b0, UNDEF};
        fr_mem[23] = {1'b0, UNDEF};
        fr_mem[24] = {1'b0, UNDEF};
        fr_mem[25] = {1'b0, UNDEF};
        fr_mem[26] = {1'b0, UNDEF};
        fr_mem[27] = {1'b0, UNDEF};
        fr_mem[28] = {1'b0, UNDEF};
        fr_mem[29] = {1'b0, UNDEF};
        fr_mem[30] = {1'b0, UNDEF};
        fr_mem[31] = {1'b0, UNDEF};
    end
    assign fr_en = fr_mem[state][16];
    assign faddr = fr_mem[state][15:0];

    reg [16:0] rd_mem [0:31];
    initial begin
        rd_mem[0] = {1'b0, UNDEF};
        rd_mem[1] = {1'b0, UNDEF};
        rd_mem[2] = {1'b0, UNDEF};
        rd_mem[3] = {1'b0, UNDEF};
        rd_mem[4] = {1'b1, (BASE | 16'd42)};
        rd_mem[5] = {1'b1, (BASE | 16'd144)};
        rd_mem[6] = {1'b0, UNDEF};
        rd_mem[7] = {1'b1, (BASE | 16'd42)};
        rd_mem[8] = {1'b1, (BASE | 16'd144)};
        rd_mem[9] = {1'b0, UNDEF};
        rd_mem[10] = {1'b0, UNDEF};
        rd_mem[11] = {1'b0, UNDEF};
        rd_mem[12] = {1'b0, UNDEF};
        rd_mem[13] = {1'b0, UNDEF};
        rd_mem[14] = {1'b0, UNDEF};
        rd_mem[15] = {1'b0, UNDEF};
        rd_mem[16] = {1'b0, UNDEF};
        rd_mem[17] = {1'b0, UNDEF};
        rd_mem[18] = {1'b0, UNDEF};
        rd_mem[19] = {1'b0, UNDEF};
        rd_mem[20] = {1'b0, UNDEF};
        rd_mem[21] = {1'b0, UNDEF};
        rd_mem[22] = {1'b0, UNDEF};
        rd_mem[23] = {1'b0, UNDEF};
        rd_mem[24] = {1'b0, UNDEF};
        rd_mem[25] = {1'b0, UNDEF};
        rd_mem[26] = {1'b0, UNDEF};
        rd_mem[27] = {1'b0, UNDEF};
        rd_mem[28] = {1'b0, UNDEF};
        rd_mem[29] = {1'b0, UNDEF};
        rd_mem[30] = {1'b0, UNDEF};
        rd_mem[31] = {1'b0, UNDEF};
    end
    assign rd_en = rd_mem[state][16];
    assign raddr = rd_mem[state][15:0];

    reg [32:0] wr_mem [0:31];
    initial begin
        wr_mem[0] = {1'b0, UNDEF, UNDEF};
        wr_mem[1] = {1'b0, UNDEF, UNDEF};
        wr_mem[2] = {1'b1, (BASE | 16'd42), (ZERO | 16'd420)};
        wr_mem[3] = {1'b1, (BASE | 16'd144), (ZERO | 16'd1337)};
        wr_mem[4] = {1'b0, UNDEF, UNDEF};
        wr_mem[5] = {1'b0, UNDEF, UNDEF};
        wr_mem[6] = {1'b0, UNDEF, UNDEF};
        wr_mem[7] = {1'b1, (BASE | 16'd34), (ZERO | 16'd55)};
        wr_mem[8] = {1'b1, (BASE | 16'd144), (ZERO | 16'd360)};
        wr_mem[9] = {1'b0, UNDEF, UNDEF};
        wr_mem[10] = {1'b0, UNDEF, UNDEF};
        wr_mem[11] = {1'b0, UNDEF, UNDEF};
        wr_mem[12] = {1'b0, UNDEF, UNDEF};
        wr_mem[13] = {1'b0, UNDEF, UNDEF};
        wr_mem[14] = {1'b0, UNDEF, UNDEF};
        wr_mem[15] = {1'b0, UNDEF, UNDEF};
        wr_mem[16] = {1'b0, UNDEF, UNDEF};
        wr_mem[17] = {1'b0, UNDEF, UNDEF};
        wr_mem[18] = {1'b0, UNDEF, UNDEF};
        wr_mem[19] = {1'b0, UNDEF, UNDEF};
        wr_mem[20] = {1'b0, UNDEF, UNDEF};
        wr_mem[21] = {1'b0, UNDEF, UNDEF};
        wr_mem[22] = {1'b0, UNDEF, UNDEF};
        wr_mem[23] = {1'b0, UNDEF, UNDEF};
        wr_mem[24] = {1'b0, UNDEF, UNDEF};
        wr_mem[25] = {1'b0, UNDEF, UNDEF};
        wr_mem[26] = {1'b0, UNDEF, UNDEF};
        wr_mem[27] = {1'b0, UNDEF, UNDEF};
        wr_mem[28] = {1'b0, UNDEF, UNDEF};
        wr_mem[29] = {1'b0, UNDEF, UNDEF};
        wr_mem[30] = {1'b0, UNDEF, UNDEF};
        wr_mem[31] = {1'b0, UNDEF, UNDEF};
    end
    assign wr_en = wr_mem[state][32];
    assign waddr = wr_mem[state][31:16];
    assign wdata = wr_mem[state][15:0];

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
                7: begin
                    // simultaneous read/write
                    // rdata <= ram[42];
                    // ram[34] <= 55
                end
                8: begin
                    // assert(rdata == 420)
                    if (rdata != (ZERO | 420)) begin
                        o_debug <= rdata;
                        state <= 0;
                    end
                    // read/alloc conflict
                    // rdata <= ram[144];
                    // ram[144] <= 360;
                end
                9: begin
                    // assert(rdata == 1337)
                    if (rdata != (ZERO | 1337)) begin
                        o_debug <= rdata;
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
/*
                    end else begin
                        state <= 22;  // SKIP TO THE END...
*/
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
