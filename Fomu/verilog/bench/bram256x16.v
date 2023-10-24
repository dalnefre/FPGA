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
`ifdef __ICARUS__
    reg [15:0] mem_sim [0:255];
    // Attempting to read unwritten memory produces undefined. Undefined shows
    // up red in GTK Wave, which is probably a good thing. If we wanted to
    // simulate hardware more closely, we could initialize mem_sim to zero with
    // the following initial block:
    // integer i;
    // initial begin
    //   for (i = 0; i <= 255; i = i + 1)
    //     mem_sim[i] = 0;
    // end
    assign o_rdata = (
        i_rd_en
        ? mem_sim[i_raddr]
        : 0
    );
    always @(posedge i_wclk) begin
        if (i_wr_en) begin
            mem_sim[i_waddr] <= i_wdata;
        end
    end
`else
    SB_RAM40_4K #(
        .WRITE_MODE(0),     // 256x16
        .READ_MODE(0)       // 256x16
    ) mem (
        .RDATA(o_rdata),
        .RCLK(i_rclk),
        .RCLKE(i_rd_en),  // FIXME: should be 1'b1 ?
        .RE(i_rd_en),
        .RADDR(i_raddr),
        .WCLK(i_wclk),
        .WCLKE(i_wr_en),  // FIXME: should be 1'b1 ?
        .WE(i_wr_en),
        .WADDR(i_waddr),
        .MASK(0),
        .WDATA(i_wdata)
    );
`endif
endmodule
