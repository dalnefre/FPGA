/*

Test Bench for bram.v

*/

`default_nettype none

`include "bram.v"
//`include "bram256x16.v"

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

    // instantiate BRAM
    reg wr_en;
    reg [7:0] waddr;
    reg [15:0] wdata;
    reg rd_en;
    reg [7:0] raddr;
    wire [15:0] rdata;
    bram BRAM (
        .i_clk(clk),
        .i_wr_en(wr_en),
        .i_waddr(waddr),
        .i_wdata(wdata),
        .i_rd_en(rd_en),
        .i_raddr(raddr),
        .o_rdata(rdata)
    );

    // sequence counter
    reg [3:0] seq;
    initial seq = 0;
    always @(posedge clk) begin
        seq <= seq + 1'b1;
    end

    // exercise BRAM
    initial wr_en = 1'b0;
    initial waddr = 7;
    initial wdata = 5;
    initial rd_en = 1'b0;
    initial raddr = 0;
    always @(posedge clk) begin
        wr_en <= 1'b0;  // default
        case (seq[3:2])
            2'b00 : begin
            end
            2'b01 : begin
                wr_en <= 1'b1;
                raddr <= waddr;
            end
            2'b10 : begin
                waddr <= waddr + 3;
            end
            2'b11 : begin
                wdata <= wdata + 5;
            end
            default : begin
            end
        endcase
    end
    always @(negedge clk) begin
        rd_en <= 1'b0;  // default
        case (seq[3:2])
            2'b00 : begin
                rd_en <= 1'b1;
            end
        endcase
    end

endmodule
