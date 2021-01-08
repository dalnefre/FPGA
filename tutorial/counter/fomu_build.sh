yosys -p 'synth_ice40 -json fomu_pvt.json' count_3.v count_3_fomu.v
nextpnr-ice40 --up5k --package uwg30 --pcf ../../Fomu/pcf/fomu-pvt.pcf --json fomu_pvt.json --asc fomu_pvt.asc
rm fomu_pvt.json
icepack fomu_pvt.asc fomu_pvt.bit
rm fomu_pvt.asc
cp fomu_pvt.bit fomu_pvt.dfu
dfu-suffix -v 1209 -p 70b1 -a fomu_pvt.dfu
rm fomu_pvt.bit
