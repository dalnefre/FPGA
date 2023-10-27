/*

Physical Test Bench

*/

`default_nettype none

`include "alloc_test.v"
// `include "fixture.v"

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

    // start-up delay
    reg [7:0] waiting;
    initial waiting = 63;  // wait for memory to "settle"?
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

    // drive LEDs
    assign led_r = error;
    assign led_g = passed;
    assign led_b = !running;

endmodule
