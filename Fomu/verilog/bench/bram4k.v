/*

iCE40 Dual-Ported Block RAM
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

DATA_SZ may be 16, 8, 4, or 2.

*/

`default_nettype none

module bram #(
    parameter DATA_SZ = 16, /* 16, 8, 4, 2 */   // number of bits per memory word
    // DATA_SZ x 2^ADDR_SZ = 4096 bits
    parameter ADDR_SZ = $clog2(4096 / DATA_SZ)  // number of bits in each address
) (
    input                       i_clk,          // system clock

    input                       i_wr_en,        // write request
    input         [ADDR_SZ-1:0] i_waddr,        // write address
    input         [DATA_SZ-1:0] i_wdata,        // data written

    input                       i_rd_en,        // read request
    input         [ADDR_SZ-1:0] i_raddr,        // read address
    output reg    [DATA_SZ-1:0] o_rdata         // data read
);
    // MODE=0: 256x16
    // MODE=1: 512x8
    // MODE=2: 1024x4
    // MODE=3: 2048x2
    localparam MODE = ADDR_SZ - 8;
    SB_RAM40_4K #(
        .READ_MODE(MODE),
        .WRITE_MODE(MODE)
    ) BRAM (
        .WCLKE(1'b1),
        .WCLK(i_clk),
        .WE(i_wr_en),
        .WADDR(i_waddr),
        .WDATA(i_wdata),
        .MASK(0),
        .RCLKE(1'b1),
        .RCLK(i_clk),
        .RE(i_rd_en),
        .RADDR(i_raddr),
        .RDATA(o_rdata)
    );

endmodule
