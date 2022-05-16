# VerilogTea
This is a Verilog implementation of the Tiny Encryption Algorithm.

- `ref.c` contains a reference implementation adapted from the TEA paper, and
  some discussion on endianness issues.
- `tea.v` contains the Verilog implementation
- `test.v` - a Verilog testbench

# Simulation

To run the testbench using Icarus Verilog, run:
```
iverilog tea.v test.v -o tea && vvp tea
```

The TEA paper does not give any test vectors, so we use the test vectors used
in Linux (search for `tea_tv_template`):

https://raw.githubusercontent.com/torvalds/linux/93e220a62da36f766b3188e76e234607e41488f9/crypto/testmgr.h

# Synthesis with Yosys

The module can be synthetized with [Yosys](https://github.com/YosysHQ/yosys) for the ICE40 family by running:

```
yosys synth.ys
```

This produces a verilog file `tea_synth.v` which implements this module using
the primitives available in ICE40. This also saves the .json file in a which can be used with a place-and-route tool like nextpnr.

The testbench can be used with the synthesized version by running:

```
test_synth.sh
```

## Circuit diagram

This diagrams shows how yosys synthetizes the `tea_enc_dec` module before
primitives like adders and muxes are mapped into logic-gate level. To
re-generate this diagram, run `yosys show.ys`.

![auto-generated circuit diagram](diagram.svg)
