## Serial Loopback Device

This example creates a simple loopback device.
It works like a serial port,
but simply echos any input received.
It will work at any baud-rate
because it isn't actually recognizing the input.

The user i/o pad are assigned as follows,
starting from the side with the notch:

  1. GND -- Common Ground
  2. TX -- Transmitted Data (copied from RX)
  3. RX -- Received Data (w/ pull-up if not connected)
  4. PWR -- 3v3 Level (do not connect)

Signals are expected to be LVCMOS levels.
Note that an idle serial line is held high,
and transitions to low to indicate the start
of a new character (octet).

### Serial Terminal Program

You'll have to run a serial terminal program
to communicate with the FPGA serial device.

On a Mac, determine the available devices like this:

    $ ls /dev/tty.*

Then run the `screen` program to connect
to the serial port at your desired baud-rate.

    $ screen /dev/tty.usbserial-AD0JIXTZ 9600

Use the key sequence `Ctrl-a + k` to kill the terminal session.
