/*

Test Bench for alloc.v

*/

`default_nettype none

`include "alloc_test.v"

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

    wire running;
    wire pass;
    alloc_test TEST (
        .i_clk(clk),
        .i_en(1'b1),
        .o_running(running),
        .o_pass(pass)
    );

endmodule
