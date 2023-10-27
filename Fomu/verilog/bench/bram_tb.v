/*

Test Bench for bram.v

*/

`default_nettype none

`include "bram.v"

`timescale 10ns/1ns

module test_bench;

    // dump simulation signals
    initial begin
        $dumpfile("bram.vcd");
        $dumpvars(0, test_bench);
        #1600;
        $finish;
    end

    // generate chip clock (50MHz simulation time)
    reg clk = 0;
    always begin
        #1 clk = !clk;
    end

    // start-up delay
    reg [7:0] waiting;
    initial waiting = 3;  // wait for memory to "settle"?
    always @(posedge clk) begin
        if (waiting) begin
            waiting <= waiting - 1'b1;
        end
    end

    // inputs
    wire wr_en;
    wire [7:0] waddr;
    wire [15:0] wdata;
    wire rd_en;
    wire [7:0] raddr;
    // outputs
    wire [15:0] rdata;
    // instantiate BRAM
    bram BRAM (
        .i_clk(clk),

        .i_wr_en(wr_en),
        .i_waddr(waddr),
        .i_wdata(wdata),

        .i_rd_en(rd_en),
        .i_raddr(raddr),
        .o_rdata(rdata)
    );

    //
    // test fixture
    //

    reg [7:0] state;  // 8-bit state-machine
    initial state = 1;

    wire o_running;  // test is running
    assign o_running = !waiting && (state != 0);

    reg o_passed;  // test passed
    initial o_passed = 1'b0;

    // FIXME: consider combinational "always @(*)" block
    assign wr_en = ((state == 2) || (state == 3));
    assign waddr =
        (state == 2)
        ? 42
        : (
            (state == 3)
            ? 144
            : 0
        );
    assign wdata =
        (state == 2)
        ? 420
        : (
            (state == 3)
            ? 1337
            : 0
        );
    assign rd_en = ((state == 4) || (state == 5));
    assign raddr =
        (state == 4)
        ? 42
        : (
            (state == 5)
            ? 144
            : 0
        );

    always @(posedge clk) begin
        if (o_running) begin
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
                    if (rdata != 420) begin
                        state <= 0;
                    end
                    // rdata <= ram[144]
                end
                6: begin
                    // assert(rdata == 1337)
                    if (rdata != 1337) begin
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
