/*

iCE40 Dual-Ported Block RAM (read @ negedge)
(derived from FPGA-TN-02002-1-7-Memory-Usage-Guide-for-iCE40-Devices.pdf)

    +-----------------+
    | bram (4kb)      |
    |                 |
--->|i_rd_en   i_wr_en|<---
=A=>|i_raddr   i_waddr|<=A=
<=D=|o_rdata   i_wdata|<=D=
    |                 |
 +->|i_clk            |
 |  +-----------------+

*/

`default_nettype none

module bram #(
    // DATA_SZ x MEM_MAX = 4096 bits
    parameter DATA_SZ           = 16,                           // number of bits per memory word
    parameter ADDR_SZ           = 8,                            // number of bits in each address
    parameter MEM_MAX           = (1<<ADDR_SZ)                  // maximum memory memory address
) (
    input                       i_clk,                          // system clock

    input                       i_wr_en,                        // write request
    input         [ADDR_SZ-1:0] i_waddr,                        // write address
    input         [DATA_SZ-1:0] i_wdata,                        // data written

    input                       i_rd_en,                        // read request
    input         [ADDR_SZ-1:0] i_raddr,                        // read address
    output reg    [DATA_SZ-1:0] o_rdata                         // data read
);

    SB_RAM40_4KNR BRAM (
        .WCLKE(1'b1),
        .WCLK(i_clk),
        .WE(i_wr_en),
        .WADDR(i_waddr),
        .WDATA(i_wdata),
        .MASK(0),
        .RCLKE(1'b1),
//        .RCLK(i_clk),  // not present on 4KNR?
        .RE(i_rd_en),
        .RADDR(i_raddr),
        .RDATA(o_rdata)
    );

endmodule
