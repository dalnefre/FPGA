## Fomu "touch-pad" Button Demo

This example uses the "touch-pads" on the edge of the Fomu
to simulate a three-button mouse-like input device.

The user i/o pad are assigned as follows,
starting from the side with the notch:

  1. LEFT -- Touch Left (w/ pull-up)
  2. GND -- Common Ground
  3. GND -- Common Ground
  4. RIGHT -- Touch Right (w/ pull-up)

Because of the configured internal pull-ups,
the touch signals will report high (1)
when there is no contact.
The touch signal will report low (0)
when a touch pad is shorted to ground
(like the center pads)
by some conductive material.

The touch signals are used
to drive the RGB LED.
Red for left-only.
Green for right-only.
Blue for both right and left.

### Clock Synchronizer

The raw touch signals are naturally "bouncy".
Like any external signal,
they need to be synchronized
with the local clock-domain
to avoid [metastability](https://en.wikipedia.org/wiki/Metastability_(electronics)) issues.

### LED Frequency Limiter

The specifications for the iCE40 FPGA used in the Fomu
say that the LED signal frequency should stay below 64kHz.
The `led_freq` module restricts changes in the output
to a minimum frequency of 46.875kHz, ensuring conformance.
This frequency limit also extends very short pulses
so that they will light the LED long enough to be seen.
