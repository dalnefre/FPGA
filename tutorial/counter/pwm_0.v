// pwm_0.v
//
// pulse-width modulation
//

module pwm #(
  parameter N = 8                       // counter resolution
) (
  input          [N-1:0] pulse,         // pulse threshold
  input          [N-1:0] count,         // duty-cycle counter
  output                 out            // on/off output signal
);

  assign out = (count < pulse);

endmodule