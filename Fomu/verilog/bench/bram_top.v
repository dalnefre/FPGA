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
    reg [7:0] waiting;
    initial waiting = 63;  // wait for memory to "settle"?
    always @(posedge clk) begin
        if (waiting) begin
            waiting <= waiting - 1'b1;
        end
    end

    // inputs
    wire wr_en;
    wire [7:0] waddr;
    wire [15:0] wdata;
    wire rd_en;
    wire [7:0] raddr;
    // outputs
    wire [15:0] rdata;
    // instantiate BRAM
    bram BRAM (
        .i_clk(clk),

        .i_wr_en(wr_en),
        .i_waddr(waddr),
        .i_wdata(wdata),

        .i_rd_en(rd_en),
        .i_raddr(raddr),
        .o_rdata(rdata)
    );

    //
    // test fixture
    //

    reg [7:0] state;  // 8-bit state-machine
    initial state = 1;

    wire o_running;  // test is running
    assign o_running = !waiting && (state != 0);

    reg o_passed;  // test passed
    initial o_passed = 1'b0;

    // FIXME: consider combinational "always @(*)" block
    assign wr_en = ((state == 2) || (state == 3));
    assign waddr =
        (state == 2)
        ? 42
        : (
            (state == 3)
            ? 144
            : 0
        );
    assign wdata =
        (state == 2)
        ? 420
        : (
            (state == 3)
            ? 1337
            : 0
        );
    assign rd_en = ((state == 4) || (state == 5));
    assign raddr =
        (state == 4)
        ? 42
        : (
            (state == 5)
            ? 144
            : 0
        );

    always @(posedge clk) begin
        if (o_running) begin
            state <= state + 1'b1;  // default: advance to next state
            case (state)
                1: begin
                    // start state
                end
                2: begin
                    // ram[42] <= 420
                end
                3: begin
                    // ram[144] <= 1337
                end
                4: begin
                    // rdata <= ram[42]
                end
                5: begin
                    // assert(rdata == 420)
                    if (rdata != 420) begin
                        state <= 0;
                    end
                    // rdata <= ram[144]
                end
                6: begin
                    // assert(rdata == 1337)
                    if (rdata != 1337) begin
                        state <= 0;
                    end
                end
                9: begin
                    // successful completion
                    o_passed <= 1'b1;
                    state <= 0;
                end
            endcase
        end
    end

    // drive LEDs
    assign led_r = !o_running && !o_passed;
    assign led_g = !o_running && o_passed;
    assign led_b = o_running;

endmodule
