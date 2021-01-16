// usb_2_tb.v
//
// simulation test bench for usb_0.v + usb_1.v
//

`include "usb.vh"

module test_bench;

  // dump simulation signals
  initial
    begin
      $dumpfile("usb_2.vcd");
      $dumpvars(0, test_bench);
      #270;
      $finish;  // stop simulation
    end

  // generate chip clock
  reg clk = 0;
  always
    #1 clk = !clk;

  // instantiate usb transmitter
  wire usb_p, usb_n;  // D+, D- signals
  reg valid = 0;
  reg [7:0] d_out = 0;
  wire tx_rd;
  wire tx_en;
  usb_tx USB_TX (
    .clk(clk),
    .valid(valid),
    .data(d_out),
    .rd(tx_rd),
    .en(tx_en),
    .usb_p(usb_p),
    .usb_n(usb_n)
  );

  // instantiate usb receiver
  wire ready;
  wire eop;
  wire [7:0] d_in;
  usb_rx USB_RX (
    .clk(clk),
    .usb_p(usb_p),
    .usb_n(usb_n),
    .ready(ready),
    .eop(eop),
    .data(d_in)
  );

  // receive register
  reg [7:0] rcvd;
  always @(posedge clk)
    if (ready)
      rcvd <= d_in;  // capture byte received

  // transmit buffer
  reg [7:0] packet [0:15];  // 16-byte packet buffer
  reg [3:0] index = 0;
  reg [3:0] limit = 3;
  initial
    begin
      packet[4'h0] = `SYNC_BYTE;
      packet[4'h1] = `ACK_PID; //8'hFC;
      packet[4'h2] = `NAK_PID; //8'hFF;
/*
      packet[4'h3] = 8'h00;
      packet[4'h4] = 8'h00;
      packet[4'h5] = 8'h00;
      packet[4'h6] = 8'h00;
      packet[4'h7] = 8'h00;
      packet[4'h8] = 8'h00;
      packet[4'h9] = 8'h00;
      packet[4'hA] = 8'h00;
      packet[4'hB] = 8'h00;
      packet[4'hC] = 8'h00;
      packet[4'hD] = 8'h00;
      packet[4'hE] = 8'h00;
      packet[4'hF] = 8'h00;
*/
    end

  // test-data sequencer
  reg [7:0] delay = 10;  // delay timer
  always @(posedge clk)
    if (delay)  // count down to zero
      delay <= delay - 1'b1;
    else if (tx_rd)  // data read, advance
      begin
        valid <= 0;
        index <= index + 1'b1;
      end
    else if (index < limit)  // ready output
      begin
        d_out <= packet[index];
        valid <= 1;
      end

endmodule