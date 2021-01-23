// fomu_pvt.vh

// 48MHz system clock
`define SYS_CLK_FREQ 48_000_000

// Correctly map pins for the iCE40UP5K SB_RGBA_DRV hard macro.
`define GREENPWM RGB0PWM
`define REDPWM   RGB1PWM
`define BLUEPWM  RGB2PWM

// Parameters from iCE40 UltraPlus LED Driver Usage Guide, pages 19-20
`define RGBA_CURRENT_MODE_FULL "0b0"
`define RGBA_CURRENT_MODE_HALF "0b1"
// Current levels in Full / Half mode
`define RGBA_CURRENT_04mA_02mA "0b000001"
`define RGBA_CURRENT_08mA_04mA "0b000011"
`define RGBA_CURRENT_12mA_06mA "0b000111"
`define RGBA_CURRENT_16mA_08mA "0b001111"
`define RGBA_CURRENT_20mA_10mA "0b011111"
`define RGBA_CURRENT_24mA_12mA "0b111111"
