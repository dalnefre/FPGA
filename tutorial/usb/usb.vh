// usb.vh
//
// USB definitions
//

`define LINE_J (2'b10)
`define LINE_K (2'b01)
`define LINE_Z (2'b00)

`define SYNC_BYTE (8'h80)
`define ACK_PID (8'hD2)
`define NAK_PID (8'h5A)

/*
The following waveform represents transmission of a USB NAK packet.
   ___   _   _   _     ___       ___        ___
D+    \_/ \_/ \_/ \___/   \_____/   \______/
       _   _   _   ___     _____     _
D- ___/ \_/ \_/ \_/   \___/     \___/ \________

DIFF   K J K J K J K K J J K K K J J K Z Z J

NRZI   0 0 0 0 0 0 0 1 0 1 0 1 1 0 1 0 - - -
      |--clock sync---|--NAK packet---|-EOP-|
*/
