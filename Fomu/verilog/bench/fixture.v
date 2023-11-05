/*

Test fixture for the Linked-Memory Allocator

    +---------------+
    | alloc_test    |
    |               |
--->|i_en  o_running|--->
    |       o_passed|--->
    |        o_debug|--->
    |               |
 +->|i_clk          |
 |  +---------------+

This component runs some tests on alloc.v, producing a pass or fail result.
Activity is paused whilst i_en is low. During operation, o_running remains
high. Once o_running goes low, the value of o_passed indicates success or failure.

*/

`default_nettype none

`include "alloc.v"
//`include "alloc.james.v"

module alloc_test (
    input                       i_clk,                          // system clock
    input                       i_en,                           // testing enabled
    output                      o_running,
    output reg                  o_passed,
    output reg           [63:0] o_debug
);
    // reserved constants
    localparam UNDEF            = 16'h0000;                     // undefined value
    localparam NIL              = 16'h0001;                     // the empty list
    localparam TRUE             = 16'h0002;                     // boolean true
    localparam FALSE            = 16'h0003;                     // boolean false
    localparam UNIT             = 16'h0004;                     // inert result
    localparam ZERO             = 16'h8000;                     // fixnum +0
    localparam BASE             = 16'h5000;                     // offset 0 into RAM

    assign o_running = i_en && (state != STOP);

    initial o_passed = 1'b0;
    initial o_debug = UNDEF;

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
        .o_rdata(rdata)
    );
    wire [15:0] aaddr;
    wire [15:0] rdata;

    //
    // test script
    //

    wire al_en          = script[state][122];
    wire [15:0] adata   = script[state][121:106];
    wire acmp           = script[state][105];
    wire [15:0] axpct   = script[state][104:89];
    wire fr_en          = script[state][88];
    wire [15:0] faddr   = script[state][87:72];
    wire [4:0] next     = script[state][71:67];
    wire wr_en          = script[state][66];
    wire [15:0] waddr   = script[state][65:50];
    wire [15:0] wdata   = script[state][49:34];
    wire rd_en          = script[state][33];
    wire [15:0] raddr   = script[state][32:17];
    wire rcmp           = script[state][16];
    wire [15:0] rxpct   = script[state][15:0];

    reg [4:0] state = 5'h01;  // 5-bit state-machine
    localparam STOP = 5'h00;
    localparam LOOP = 5'h0F;
    localparam DONE = 5'h1F;
    reg [122:0] script [0:31];  // script indexed by state
    initial begin
        // al_en,    adata, acmp,    axpct, fr_en,    faddr,    next,
        // wr_en,    waddr,    wdata, rd_en,    raddr, rcmp,    rxpct
        script[STOP]  =  // stop state (looping)
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,    STOP,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h01] =  // start state
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h02,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h02] =  // ram[^50FF] <= $BE11
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h03,
            1'b1, 16'h50FF, 16'hBE11,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h03] =  // ram[^5095] <= $C0DE
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h04,
            1'b1, 16'h5095, 16'hC0DE,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h04] =  // rdata <= ram[^50FF]
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h05,
            1'b0, 16'h0000, 16'h0000,  1'b1, 16'h50FF, 1'b0, 16'h0000  };
        script[5'h05] =  // assert(rdata == $BE11); rdata <= ram[^5095]
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h06,
            1'b0, 16'h0000, 16'h0000,  1'b1, 16'h5095, 1'b1, 16'hBE11  };
        script[5'h06] =  // assert(rdata == $C0DE)
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h07,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b1, 16'hC0DE  };
        script[5'h07] =  // rdata <= ram[^50FF]; ram[^5034] <= $D05E
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h08,
            1'b1, 16'h5034, 16'hD05E,  1'b1, 16'h50FF, 1'b0, 16'h0000  };
        script[5'h08] =  // assert(rdata == $BE11)
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h09,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b1, 16'hBE11  };
        script[5'h09] =  // rdata <= ram[^5034]; ram[^5034] <= $EA5E
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h0A,
            1'b1, 16'h5034, 16'hEA5E,  1'b1, 16'h5034, 1'b0, 16'h0000  };
        script[5'h0A] =  // assert(rdata == $EA5E) --- write before read
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h0B,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b1, 16'hEA5E  };
        script[5'h0B] =  // no-op
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h0C,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h0C] =  // no-op
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h0D,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h0D] =  // no-op
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h0E,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h0E] =  // no-op
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h10,  // <-- skip to 10
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[LOOP]  =  // no-op (loop forever...)
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,    LOOP,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h10] =  // aaddr <= alloc($FADE)
        {   1'b1, 16'hFADE, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h11,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h11] =  // assert(aaddr == ^5000); aaddr <= alloc($AB1E)
        {   1'b1, 16'hAB1E, 1'b1, 16'h5000,  1'b0, 16'h0000,   5'h12,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h12] =  // assert(aaddr == ^5001); aaddr <= alloc($B055)
        {   1'b1, 16'hB055, 1'b1, 16'h5001,  1'b0, 16'h0000,   5'h13,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h13] =  // assert(aaddr == ^5002)
        {   1'b0, 16'h0000, 1'b1, 16'h5002,  1'b0, 16'h0000,   5'h14,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h14] =  // aaddr <= alloc($CE11); free(^5001)
        {   1'b1, 16'hCE11, 1'b0, 16'h0000,  1'b1, 16'h5001,   5'h15,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h15] =  // assert(aaddr == ^5001); free(^5002)
        {   1'b0, 16'h0000, 1'b1, 16'h5001,  1'b1, 16'h5002,   5'h16,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h16] =  // free(^5001)
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b1, 16'h5001,   5'h17,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h17] =  // aaddr <= alloc($DEAF)
        {   1'b1, 16'hDEAF, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h18,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h18] =  // assert(aaddr == ^5001); aaddr <= alloc($E15E)
        {   1'b1, 16'hE15E, 1'b1, 16'h5001,  1'b0, 16'h0000,   5'h19,  // <-- skip to 1C?
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h19] =  // assert(aaddr == ^5002); aaddr <= alloc($F001)
        {   1'b1, 16'hF001, 1'b1, 16'h5002,  1'b0, 16'h0000,   5'h1A,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h1A] =  // assert(aaddr == ^5003)
        {   1'b0, 16'h0000, 1'b1, 16'h5003,  1'b0, 16'h0000,   5'h1B,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h1B] =  // no-op
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,    DONE,  // <-- skip to DONE
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h1C] =  // assert(aaddr == ^5002)
        {   1'b0, 16'h0000, 1'b1, 16'h5002,  1'b0, 16'h0000,   5'h1D,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h1D] =  // no-op
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h1E,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[5'h1E] =  // no-op
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,   5'h1F,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
        script[DONE]  =  // done state (success)
        {   1'b0, 16'h0000, 1'b0, 16'h0000,  1'b0, 16'h0000,    STOP,
            1'b0, 16'h0000, 16'h0000,  1'b0, 16'h0000, 1'b0, 16'h0000  };
    end

    always @(posedge i_clk) begin
        if (o_running) begin
            if (state == DONE) begin
                // register success
                o_passed <= 1'b1;
            end
            state <= next;  // default transition
            if (acmp) begin
                if (aaddr != axpct) begin
                    state <= STOP;  // stop (failed)
                end
            end
            if (rcmp) begin
                if (rdata != rxpct) begin
                    state <= STOP;  // stop (failed)
                end
            end
        end
    end

/*
    always @(posedge i_clk) begin
        if (o_running) begin
            state <= state + 1'b1;  // default: advance to next state
            case (r_state)  // verify one clock behind action
                1: // start state
                2: // ram[42] <= 420
                3: // ram[144] <= 1337
                4: // rdata <= ram[42]
                5: // assert(rdata == 420); rdata <= ram[144]
                6: // assert(rdata == 1337)
                7: // rdata <= ram[42]; ram[34] <= 55 --- simultaneous read/write
                8: // assert(rdata == 420); rdata <= ram[144]; ram[144] <= 360 --- read/write same address
//                9: // assert(rdata == 1337) --- read-before-write
                9: // assert(rdata == 360) --- write-before-read
                10: // aaddr <= alloc(256)
                11: // assert(aaddr == ^5..0); aaddr <= alloc(257)
                12: // assert(aaddr == ^5..1); aaddr <= alloc(258)
                13: // assert(aaddr == ^5..2)
                15: // free(^5..2)
                16: // free(^5..1)
                17: // aaddr <= alloc(259)
                18: // assert(aaddr == ^5..1); free(^5..0); aaddr <= alloc(260)
                19: // assert(aaddr == ^5..0); aaddr <= alloc(261)
                20: // assert(aaddr == ^5..2)
                25: // successful completion
            endcase
        end
    end
*/

endmodule
