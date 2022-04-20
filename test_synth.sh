#!/usr/bin/env bash
yosys synth.ys
iverilog -o tea -DNO_ICE40_DEFAULT_ASSIGNMENTS tea_synth.v test.v `yosys-config --datdir/ice40/cells_sim.v`