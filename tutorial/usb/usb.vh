// usb.vh
//
// USB definitions
//

`define LINE_J (2'b10)
`define LINE_K (2'b01)
`define LINE_Z (2'b00)

/*
The following waveform represents transmission of a USB NAK packet.
   _____   _   _   _     ___       ___
D+      \_/ \_/ \_/ \___/   \_____/   \________
         _   _   _   ___     _____     _
D- _____/ \_/ \_/ \_/   \___/     \___/ \______

DIFF     K J K J K J K K J J K K K J J K Z Z J

NRZI     0 0 0 0 0 0 0 1 0 1 0 1 1 0 1 0 - - -
        |--clock sync---|--NAK packet---|-EOP-|
*/
