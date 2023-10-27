/*

Test Bench for alloc.v

*/

`default_nettype none

`include "alloc_test.v"
// `include "fixture.v"

`timescale 10ns/1ns

module test_bench;

    // dump simulation signals
    initial begin
        $dumpfile("alloc.vcd");
        $dumpvars(0, test_bench);
        #1000;
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

    wire running;
    wire [15:0] debug;
    wire passed;
    wire error;
    alloc_test TEST (
        .i_clk(clk),
        .i_en(!waiting),
        .o_running(running),
        .o_debug(debug),
        .o_passed(passed),
        .o_error(error)
    );

endmodule
