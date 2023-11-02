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

    // start-up delay
/*
    wire run = 1'b1;
*/
    reg run = 1'b0;
    reg [5:0] waiting = 0;
    always @(posedge clk) begin
        // wait for memory to "settle"?
        if (!run) begin
            {run, waiting} <= {1'b0, waiting} + 1'b1;
        end
    end

    // instantiate BRAM
    bram BRAM (
        .i_clk(clk),

        .i_wr_en(wr),
        .i_waddr(waddr),
        .i_wdata(wdata),

        .i_rd_en(rd),
        .i_raddr(raddr),
        .o_rdata(actual)
    );
    wire [15:0] actual;

    //
    // test fixture
    //

    reg [3:0] state = 4'h1;  // 4-bit state-machine
    localparam STOP = 4'h0;
    localparam DONE = 4'hF;

    reg [54:0] script [0:15];  // script indexed by state
    initial begin    //    wr, waddr,    wdata,    rd, raddr,   expect,  cmp  next
        script[STOP] = { 1'b0, 8'h00, 16'h0000,  1'b0, 8'h00, 16'h0000, 1'b0, STOP };
        script[4'h1] = { 1'b0, 8'h00, 16'h0000,  1'b0, 8'h00, 16'h0000, 1'b0, 4'h2 };
        script[4'h2] = { 1'b1, 8'hFF, 16'hBE11,  1'b0, 8'h00, 16'h0000, 1'b0, 4'h3 };
        script[4'h3] = { 1'b1, 8'h95, 16'hC0DE,  1'b0, 8'h00, 16'h0000, 1'b0, 4'h4 };
        script[4'h4] = { 1'b0, 8'h00, 16'h0000,  1'b1, 8'hFF, 16'h0000, 1'b0, 4'h5 };
        script[4'h5] = { 1'b0, 8'h00, 16'h0000,  1'b1, 8'h95, 16'hBE11, 1'b1, 4'h6 };
        script[4'h6] = { 1'b0, 8'h00, 16'h0000,  1'b0, 8'h00, 16'hC0DE, 1'b1, 4'h7 };
        script[4'h7] = { 1'b0, 8'h00, 16'h0000,  1'b0, 8'h00, 16'h0000, 1'b0, 4'h8 };
        script[4'h8] = { 1'b0, 8'h00, 16'h0000,  1'b0, 8'h00, 16'h0000, 1'b0, 4'h9 };
        script[4'h9] = { 1'b0, 8'h00, 16'h0000,  1'b0, 8'h00, 16'h0000, 1'b0, 4'hA };
        script[4'hA] = { 1'b0, 8'h00, 16'h0000,  1'b0, 8'h00, 16'h0000, 1'b0, 4'hB };
        script[4'hB] = { 1'b0, 8'h00, 16'h0000,  1'b0, 8'h00, 16'h0000, 1'b0, 4'hC };
        script[4'hC] = { 1'b0, 8'h00, 16'h0000,  1'b0, 8'h00, 16'h0000, 1'b0, 4'hD };
        script[4'hD] = { 1'b0, 8'h00, 16'h0000,  1'b0, 8'h00, 16'h0000, 1'b0, 4'hE };
        script[4'hE] = { 1'b0, 8'h00, 16'h0000,  1'b0, 8'h00, 16'h0000, 1'b0, 4'hF };
        script[DONE] = { 1'b0, 8'h00, 16'h0000,  1'b0, 8'h00, 16'h0000, 1'b0, STOP };
    end
    // inputs
    wire wr             = script[state][54];
    wire [7:0] waddr    = script[state][53:46];
    wire [15:0] wdata   = script[state][45:30];
    wire rd             = script[state][29];
    wire [7:0] raddr    = script[state][28:21];
    // outputs
    wire [15:0] expect  = script[state][20:5];
    wire cmp            = script[state][4];
    wire [3:0] next     = script[state][3:0];

    // test is running
    wire o_running = run && (state != STOP);

    // test passed
    reg o_passed = 1'b0;

    always @(posedge clk) begin
        if (o_running) begin
            if (state == DONE) begin
                // register success
                o_passed <= 1'b1;
            end
            state <= next;  // default transition
            if (cmp) begin
                if (actual != expect) begin
                    state <= STOP;  // stop (failed)
                end
            end
        end
    end

    // drive LEDs
    assign led_r = !o_running && !o_passed;
    assign led_g = !o_running && o_passed;
    assign led_b = o_running;

endmodule
