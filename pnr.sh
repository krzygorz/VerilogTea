#/usr/bin/env bash

yosys synth.ys
nextpnr-ice40 --json tea_synth.json --pcf-allow-unconstrained --gui --hx8k --package ct256
