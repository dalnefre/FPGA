/*

Physical Test Bench

*/

`default_nettype none

//`include "bram.v"
`include "bram4k.v"

module top (
    input                       clki,                           // 48MHz oscillator input on Fomu-PVT
    output                      rgb0,                           // RGB LED pin 0 (**DO NOT** drive directly)
    output                      rgb1,                           // RGB LED pin 1 (**DO NOT** drive directly)
    output                      rgb2,                           // RGB LED pin 2 (**DO NOT** drive directly)
    output                      usb_dp,                         // USB D+
    output                      usb_dn,                         // USB D-
    output                      usb_dp_pu                       // USB D+ pull-up
);
    parameter CLK_FREQ          = 48_000_000;                   // clock frequency (Hz)

    // disable Fomu USB
    assign usb_dp = 1'b0;
    assign usb_dn = 1'b0;
    assign usb_dp_pu = 1'b0;

    // connect system clock (with buffering)
    wire clk;
    SB_GB clk_gb (
        .USER_SIGNAL_TO_GLOBAL_BUFFER(clki),
        .GLOBAL_BUFFER_OUTPUT(clk)
    );

    // connect RGB LED driver (see: FPGA-TN-1288-ICE40LEDDriverUsageGuide.pdf)
    wire led_r;
    wire led_g;
    wire led_b;
    SB_RGBA_DRV #(
        .CURRENT_MODE("0b1"),                                   // half current
        .RGB0_CURRENT("0b001111"),                              // 8 mA
        .RGB1_CURRENT("0b000011"),                              // 4 mA
        .RGB2_CURRENT("0b000011")                               // 4 mA
    ) RGBA_DRIVER (
        .CURREN(1'b1),
        .RGBLEDEN(1'b1),
        .RGB0PWM(led_g),                                        // green
        .RGB1PWM(led_r),                                        // red
        .RGB2PWM(led_b),                                        // blue
        .RGB0(rgb0),
        .RGB1(rgb1),
        .RGB2(rgb2)
    );

    // instantiate BRAM
    reg wr_en;
    reg [7:0] waddr;
    reg [15:0] wdata;
    reg rd_en;
    reg [7:0] raddr;
    wire [15:0] rdata;
/*
    SB_RAM40_4K BRAM (
        .RDATA(rdata),
        .RCLK(clk),
        .RCLKE(1'b1),
        .RE(rd_en),
        .RADDR(raddr),
        .WCLK(clk),
        .WCLKE(1'b1),
        .WE(wr_en),
        .WADDR(waddr),
        .MASK(0),
        .WDATA(wdata)
    );
*/
    bram BRAM (
        .i_clk(clk),
        .i_wr_en(wr_en),
        .i_waddr(waddr),
        .i_wdata(wdata),
        .i_rd_en(rd_en),
        .i_raddr(raddr),
        .o_rdata(rdata),
    );

    // sequence counter
    reg [3:0] seq;
    initial seq = 0;
    always @(posedge clk)
        seq <= seq + 1'b1;

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

    // drive LEDs
    assign led_r = rd_en;
    assign led_g = (rdata == wdata);
    assign led_b = waddr[0];

endmodule
