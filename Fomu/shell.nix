# Running nix-shell from the current directory will drop you into a shell with
# the Fomu development toolchain available. This includes yosys for synthesis,
# nextpnr for place and route, iverilog for simulation, and GTK Wave for wave
# visualization.

# Download Nix from https://nixos.org/download.html.

# We pin the dependencies to a specific nixpkgs version. They can be upgraded
# by replacing the hash below with a more recent one obtained from
# https://status.nixos.org.

{
    pkgs ? import (
        fetchTarball
        "https://github.com/NixOS/nixpkgs/archive/51d906d2341c.tar.gz"
    ) {}
}:

pkgs.mkShell {
    buildInputs = [
        pkgs.dfu-util           # https://dfu-util.sourceforge.net
        pkgs.gtkwave            # https://gtkwave.sourceforge.net
        pkgs.icestorm           # https://github.com/YosysHQ/icestorm
        pkgs.nextpnr            # https://github.com/YosysHQ/nextpnr
        pkgs.verilog            # https://github.com/steveicarus/iverilog
        pkgs.yosys              # https://github.com/YosysHQ/yosys
    ];
}
