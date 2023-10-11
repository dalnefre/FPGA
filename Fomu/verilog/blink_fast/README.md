## Fast Counter Demo

This example uses a fast-counter strategy
to implement a simple RGB LED blinker.

### Reference Design

The original [RGB LED blinker](../blink_rgb/top.v)
uses a single 29-bit counter
to generate the blink patterns.
Building this design for the Fomu
produces the following results:

```
Info: Device utilisation:
Info:            ICESTORM_LC:    33/ 5280     0%
Info:           ICESTORM_RAM:     0/   30     0%
Info:                  SB_IO:     4/   96     4%
Info:                  SB_GB:     1/    8    12%
Info:           ICESTORM_PLL:     0/    1     0%
Info:            SB_WARMBOOT:     0/    1     0%
Info:           ICESTORM_DSP:     0/    8     0%
Info:         ICESTORM_HFOSC:     0/    1     0%
Info:         ICESTORM_LFOSC:     0/    1     0%
Info:                 SB_I2C:     0/    2     0%
Info:                 SB_SPI:     0/    2     0%
Info:                 IO_I3C:     0/    2     0%
Info:            SB_LEDDA_IP:     0/    1     0%
Info:            SB_RGBA_DRV:     1/    1   100%
Info:         ICESTORM_SPRAM:     0/    4     0%
...
Info: Critical path report for clock 'clk' (posedge -> posedge):
Info: curr total
Info:  1.4  1.4  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_LC.O
Info:  1.8  3.2    Net counter[0] budget 9.028000 ns (1,26) -> (1,27)
Info:                Sink $nextpnr_ICESTORM_LC_0.I1
Info:  0.7  3.8  Source $nextpnr_ICESTORM_LC_0.COUT
Info:  0.0  3.8    Net $nextpnr_ICESTORM_LC_0$O budget 0.000000 ns (1,27) -> (1,27)
Info:                Sink led_b_SB_CARRY_I1_CO_SB_CARRY_CO_14$CARRY.CIN
Info:  0.3  4.1  Source led_b_SB_CARRY_I1_CO_SB_CARRY_CO_14$CARRY.COUT
Info:  0.0  4.1    Net led_b_SB_CARRY_I1_CO[2] budget 0.000000 ns (1,27) -> (1,27)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_9_LC.CIN
Info:  0.3  4.4  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_9_LC.COUT
Info:  0.0  4.4    Net led_b_SB_CARRY_I1_CO[3] budget 0.000000 ns (1,27) -> (1,27)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_8_LC.CIN
Info:  0.3  4.7  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_8_LC.COUT
Info:  0.0  4.7    Net led_b_SB_CARRY_I1_CO[4] budget 0.000000 ns (1,27) -> (1,27)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_7_LC.CIN
Info:  0.3  4.9  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_7_LC.COUT
Info:  0.0  4.9    Net led_b_SB_CARRY_I1_CO[5] budget 0.000000 ns (1,27) -> (1,27)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_6_LC.CIN
Info:  0.3  5.2  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_6_LC.COUT
Info:  0.0  5.2    Net led_b_SB_CARRY_I1_CO[6] budget 0.000000 ns (1,27) -> (1,27)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_5_LC.CIN
Info:  0.3  5.5  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_5_LC.COUT
Info:  0.0  5.5    Net led_b_SB_CARRY_I1_CO[7] budget 0.000000 ns (1,27) -> (1,27)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_4_LC.CIN
Info:  0.3  5.8  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_4_LC.COUT
Info:  0.6  6.3    Net led_b_SB_CARRY_I1_CO[8] budget 0.560000 ns (1,27) -> (1,28)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_3_LC.CIN
Info:  0.3  6.6  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_3_LC.COUT
Info:  0.0  6.6    Net led_b_SB_CARRY_I1_CO[9] budget 0.000000 ns (1,28) -> (1,28)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_2_LC.CIN
Info:  0.3  6.9  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_2_LC.COUT
Info:  0.0  6.9    Net led_b_SB_CARRY_I1_CO[10] budget 0.000000 ns (1,28) -> (1,28)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_1_LC.CIN
Info:  0.3  7.2  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_1_LC.COUT
Info:  0.0  7.2    Net led_b_SB_CARRY_I1_CO[11] budget 0.000000 ns (1,28) -> (1,28)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_25_LC.CIN
Info:  0.3  7.4  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_25_LC.COUT
Info:  0.0  7.4    Net led_b_SB_CARRY_I1_CO[12] budget 0.000000 ns (1,28) -> (1,28)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_24_LC.CIN
Info:  0.3  7.7  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_24_LC.COUT
Info:  0.0  7.7    Net led_b_SB_CARRY_I1_CO[13] budget 0.000000 ns (1,28) -> (1,28)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_23_LC.CIN
Info:  0.3  8.0  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_23_LC.COUT
Info:  0.0  8.0    Net led_b_SB_CARRY_I1_CO[14] budget 0.000000 ns (1,28) -> (1,28)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_22_LC.CIN
Info:  0.3  8.3  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_22_LC.COUT
Info:  0.0  8.3    Net led_b_SB_CARRY_I1_CO[15] budget 0.000000 ns (1,28) -> (1,28)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_21_LC.CIN
Info:  0.3  8.6  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_21_LC.COUT
Info:  0.6  9.1    Net led_b_SB_CARRY_I1_CO[16] budget 0.560000 ns (1,28) -> (1,29)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_20_LC.CIN
Info:  0.3  9.4  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_20_LC.COUT
Info:  0.0  9.4    Net led_b_SB_CARRY_I1_CO[17] budget 0.000000 ns (1,29) -> (1,29)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_19_LC.CIN
Info:  0.3  9.7  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_19_LC.COUT
Info:  0.0  9.7    Net led_b_SB_CARRY_I1_CO[18] budget 0.000000 ns (1,29) -> (1,29)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_18_LC.CIN
Info:  0.3  9.9  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_18_LC.COUT
Info:  0.0  9.9    Net led_b_SB_CARRY_I1_CO[19] budget 0.000000 ns (1,29) -> (1,29)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_17_LC.CIN
Info:  0.3 10.2  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_17_LC.COUT
Info:  0.0 10.2    Net led_b_SB_CARRY_I1_CO[20] budget 0.000000 ns (1,29) -> (1,29)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_15_LC.CIN
Info:  0.3 10.5  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_15_LC.COUT
Info:  0.0 10.5    Net led_b_SB_CARRY_I1_CO[21] budget 0.000000 ns (1,29) -> (1,29)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_14_LC.CIN
Info:  0.3 10.8  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_14_LC.COUT
Info:  0.0 10.8    Net led_b_SB_CARRY_I1_CO[22] budget 0.000000 ns (1,29) -> (1,29)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_13_LC.CIN
Info:  0.3 11.1  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_13_LC.COUT
Info:  0.0 11.1    Net led_b_SB_CARRY_I1_CO[23] budget 0.000000 ns (1,29) -> (1,29)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_12_LC.CIN
Info:  0.3 11.3  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_12_LC.COUT
Info:  0.6 11.9    Net led_b_SB_CARRY_I1_CO[24] budget 0.560000 ns (1,29) -> (1,30)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_11_LC.CIN
Info:  0.3 12.2  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_11_LC.COUT
Info:  0.0 12.2    Net led_b_SB_CARRY_I1_CO[25] budget 0.000000 ns (1,30) -> (1,30)
Info:                Sink led_b_SB_LUT4_I2_O_SB_LUT4_O_10_LC.CIN
Info:  0.3 12.4  Source led_b_SB_LUT4_I2_O_SB_LUT4_O_10_LC.COUT
Info:  0.0 12.4    Net led_b_SB_CARRY_I1_CO[26] budget 0.000000 ns (1,30) -> (1,30)
Info:                Sink led_b_SB_LUT4_I2_LC.CIN
Info:  0.3 12.7  Source led_b_SB_LUT4_I2_LC.COUT
Info:  0.0 12.7    Net led_b_SB_CARRY_I1_CO[27] budget 0.000000 ns (1,30) -> (1,30)
Info:                Sink led_g_SB_LUT4_I2_LC.CIN
Info:  0.3 13.0  Source led_g_SB_LUT4_I2_LC.COUT
Info:  0.7 13.7    Net led_b_SB_CARRY_I1_CO[28] budget 0.660000 ns (1,30) -> (1,30)
Info:                Sink led_r_SB_LUT4_I2_LC.I3
Info:  0.8 14.5  Setup led_r_SB_LUT4_I2_LC.I3
Info: 10.4 ns logic, 4.1 ns routing
...
Info: Max frequency for clock 'clk': 69.04 MHz (PASS at 48.00 MHz)
```

### Fast-Counter Design (2-stage)

```
Info: Device utilisation:
Info:            ICESTORM_LC:    38/ 5280     0%
Info:           ICESTORM_RAM:     0/   30     0%
Info:                  SB_IO:     4/   96     4%
Info:                  SB_GB:     1/    8    12%
Info:           ICESTORM_PLL:     0/    1     0%
Info:            SB_WARMBOOT:     0/    1     0%
Info:           ICESTORM_DSP:     0/    8     0%
Info:         ICESTORM_HFOSC:     0/    1     0%
Info:         ICESTORM_LFOSC:     0/    1     0%
Info:                 SB_I2C:     0/    2     0%
Info:                 SB_SPI:     0/    2     0%
Info:                 IO_I3C:     0/    2     0%
Info:            SB_LEDDA_IP:     0/    1     0%
Info:            SB_RGBA_DRV:     1/    1   100%
Info:         ICESTORM_SPRAM:     0/    4     0%
...
Info: Critical path report for clock 'clk' (posedge -> posedge):
Info: curr total
Info:  1.4  1.4  Source cnt_0_SB_LUT4_I3_LC.O
Info:  1.8  3.2    Net cnt_0[0] budget 13.420000 ns (2,27) -> (3,27)
Info:                Sink $nextpnr_ICESTORM_LC_1.I1
Info:  0.7  3.8  Source $nextpnr_ICESTORM_LC_1.COUT
Info:  0.0  3.8    Net $nextpnr_ICESTORM_LC_1$O budget 0.000000 ns (3,27) -> (3,27)
Info:                Sink cnt_0_SB_LUT4_I2_8_LC.CIN
Info:  0.3  4.1  Source cnt_0_SB_LUT4_I2_8_LC.COUT
Info:  0.0  4.1    Net cnt_0_SB_CARRY_CI_CO[2] budget 0.000000 ns (3,27) -> (3,27)
Info:                Sink cnt_0_SB_LUT4_I2_7_LC.CIN
Info:  0.3  4.4  Source cnt_0_SB_LUT4_I2_7_LC.COUT
Info:  0.0  4.4    Net cnt_0_SB_CARRY_CI_CO[3] budget 0.000000 ns (3,27) -> (3,27)
Info:                Sink cnt_0_SB_LUT4_I2_6_LC.CIN
Info:  0.3  4.7  Source cnt_0_SB_LUT4_I2_6_LC.COUT
Info:  0.0  4.7    Net cnt_0_SB_CARRY_CI_CO[4] budget 0.000000 ns (3,27) -> (3,27)
Info:                Sink cnt_0_SB_LUT4_I2_5_LC.CIN
Info:  0.3  4.9  Source cnt_0_SB_LUT4_I2_5_LC.COUT
Info:  0.0  4.9    Net cnt_0_SB_CARRY_CI_CO[5] budget 0.000000 ns (3,27) -> (3,27)
Info:                Sink cnt_0_SB_LUT4_I2_4_LC.CIN
Info:  0.3  5.2  Source cnt_0_SB_LUT4_I2_4_LC.COUT
Info:  0.0  5.2    Net cnt_0_SB_CARRY_CI_CO[6] budget 0.000000 ns (3,27) -> (3,27)
Info:                Sink cnt_0_SB_LUT4_I2_3_LC.CIN
Info:  0.3  5.5  Source cnt_0_SB_LUT4_I2_3_LC.COUT
Info:  0.0  5.5    Net cnt_0_SB_CARRY_CI_CO[7] budget 0.000000 ns (3,27) -> (3,27)
Info:                Sink cnt_0_SB_LUT4_I2_2_LC.CIN
Info:  0.3  5.8  Source cnt_0_SB_LUT4_I2_2_LC.COUT
Info:  0.6  6.3    Net cnt_0_SB_CARRY_CI_CO[8] budget 0.560000 ns (3,27) -> (3,28)
Info:                Sink cnt_0_SB_LUT4_I2_1_LC.CIN
Info:  0.3  6.6  Source cnt_0_SB_LUT4_I2_1_LC.COUT
Info:  0.0  6.6    Net cnt_0_SB_CARRY_CI_CO[9] budget 0.000000 ns (3,28) -> (3,28)
Info:                Sink cnt_0_SB_LUT4_I2_LC.CIN
Info:  0.3  6.9  Source cnt_0_SB_LUT4_I2_LC.COUT
Info:  0.0  6.9    Net cnt_0_SB_CARRY_CI_CO[10] budget 0.000000 ns (3,28) -> (3,28)
Info:                Sink cnt_0_SB_LUT4_I2_13_LC.CIN
Info:  0.3  7.2  Source cnt_0_SB_LUT4_I2_13_LC.COUT
Info:  0.0  7.2    Net cnt_0_SB_CARRY_CI_CO[11] budget 0.000000 ns (3,28) -> (3,28)
Info:                Sink cnt_0_SB_LUT4_I2_12_LC.CIN
Info:  0.3  7.4  Source cnt_0_SB_LUT4_I2_12_LC.COUT
Info:  0.0  7.4    Net cnt_0_SB_CARRY_CI_CO[12] budget 0.000000 ns (3,28) -> (3,28)
Info:                Sink cnt_0_SB_LUT4_I2_11_LC.CIN
Info:  0.3  7.7  Source cnt_0_SB_LUT4_I2_11_LC.COUT
Info:  0.0  7.7    Net cnt_0_SB_CARRY_CI_CO[13] budget 0.000000 ns (3,28) -> (3,28)
Info:                Sink cnt_0_SB_LUT4_I2_10_LC.CIN
Info:  0.3  8.0  Source cnt_0_SB_LUT4_I2_10_LC.COUT
Info:  0.7  8.7    Net cnt_0_SB_CARRY_CI_CO[14] budget 0.660000 ns (3,28) -> (3,28)
Info:                Sink cnt_0_SB_LUT4_I2_9_LC.I3
Info:  0.8  9.5  Setup cnt_0_SB_LUT4_I2_9_LC.I3
Info: 6.5 ns logic, 3.0 ns routing
...
Info: Max frequency for clock 'clk': 105.49 MHz (PASS at 48.00 MHz)
```

### Fast-Counter Design (4-stage)

```
Info: Device utilisation:
Info:            ICESTORM_LC:    45/ 5280     0%
Info:           ICESTORM_RAM:     0/   30     0%
Info:                  SB_IO:     4/   96     4%
Info:                  SB_GB:     1/    8    12%
Info:           ICESTORM_PLL:     0/    1     0%
Info:            SB_WARMBOOT:     0/    1     0%
Info:           ICESTORM_DSP:     0/    8     0%
Info:         ICESTORM_HFOSC:     0/    1     0%
Info:         ICESTORM_LFOSC:     0/    1     0%
Info:                 SB_I2C:     0/    2     0%
Info:                 SB_SPI:     0/    2     0%
Info:                 IO_I3C:     0/    2     0%
Info:            SB_LEDDA_IP:     0/    1     0%
Info:            SB_RGBA_DRV:     1/    1   100%
Info:         ICESTORM_SPRAM:     0/    4     0%
...
Info: Critical path report for clock 'clk' (posedge -> posedge):
Info: curr total
Info:  1.4  1.4  Source cnt_0_SB_LUT4_I2_5_LC.O
Info:  1.8  3.2    Net cnt_0[4] budget 3.102000 ns (3,28) -> (2,28)
Info:                Sink max_0_SB_LUT4_O_I2_SB_LUT4_O_LC.I0
Info:  1.3  4.4  Source max_0_SB_LUT4_O_I2_SB_LUT4_O_LC.O
Info:  1.8  6.2    Net max_0_SB_LUT4_O_I2 budget 3.102000 ns (2,28) -> (2,27)
Info:                Sink max_0_SB_LUT4_O_I2_SB_LUT4_I0_LC.I0
Info:  1.3  7.5  Source max_0_SB_LUT4_O_I2_SB_LUT4_I0_LC.O
Info:  1.8  9.2    Net max_0_SB_LUT4_O_I2_SB_LUT4_I0_O budget 3.311000 ns (2,27) -> (1,28)
Info:                Sink bit_25_SB_DFFE_Q_E_SB_LUT4_O_LC.I1
Info:  1.2 10.5  Source bit_25_SB_DFFE_Q_E_SB_LUT4_O_LC.O
Info:  2.4 12.9    Net bit_25_SB_DFFE_Q_E budget 3.134000 ns (1,28) -> (1,29)
Info:                Sink bit_24_SB_LUT4_I3_LC.CEN
Info:  0.1 13.0  Setup bit_24_SB_LUT4_I3_LC.CEN
Info: 5.3 ns logic, 7.7 ns routing
...
Info: Max frequency for clock 'clk': 76.80 MHz (PASS at 48.00 MHz)
```

### Summary

 Design  | Logic Cells | Logic Time | Routing Time | Max. Frequency
---------|-------------|------------|--------------|----------------
 1-stage | 33/ 5280    | 10.4 ns    | 4.1 ns       | 69.04 MHz
 2-stage | 38/ 5280    | 6.5 ns     | 3.0 ns       | 105.49 MHz
 4-stage | 45/ 5280    | 5.3 ns     | 7.7 ns       | 76.80 MHz
