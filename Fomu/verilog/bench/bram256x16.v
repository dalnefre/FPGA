/*

iCE40 Dual-Ported Block RAM in a 256x16 configuration.
That's 256 16-bit memory locations with 8-bit addresses.

See FPGA-TN-02002-1-7-Memory-Usage-Guide-for-iCE40-Devices.pdf.

    +-----------------+
    | bram (4kb)      |
    |                 |
--->|i_rd_en   i_wr_en|<---
=A=>|i_raddr   i_waddr|<=A=
<=D=|o_rdata   i_wdata|<=D=
    |                 |
 +->|i_rclk     i_wclk|<-+
 |  +-----------------+  |

*/

`default_nettype none

module bram (
    input                       i_wclk,                         // write clock
    input                       i_wr_en,                        // write request
    input                 [7:0] i_waddr,                        // write address
    input                [15:0] i_wdata,                        // data written

    input                       i_rclk,                         // read clock
    input                       i_rd_en,                        // read request
    input                 [7:0] i_raddr,                        // read address
    output               [15:0] o_rdata                         // data read
);
    SB_RAM40_4K #(
        .WRITE_MODE(0),     // 256x16
        .READ_MODE(0)       // 256x16
    ) mem (
        .RDATA(o_rdata),
        .RCLK(i_rclk),
        .RCLKE(i_rd_en),
        .RE(i_rd_en),
        .RADDR(i_raddr),
        .WCLK(i_wclk),
        .WCLKE(i_wr_en),
        .WE(i_wr_en),
        .WADDR(i_waddr),
        .MASK(0),
        .WDATA(i_wdata)
    );
endmodule
