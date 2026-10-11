# Regularity Modules

Verilog implementations and tests for arithmetic and basic logic modules.
The directory layout follows Logikbench's categories and per-module `rtl/` and
`testbench/` organization.

```text
regularity_modules/
├── Makefile
├── arithmetic/
│   ├── abs/
│   ├── adder_carry_save/
│   ├── adder_carry_skip/
│   ├── adder_ripple_carry/
│   ├── comparator/
│   ├── div_restoring/
│   ├── mul_array/
│   ├── mul_shift_add/
│   └── sin_cos_cordic/
│       ├── rtl/
│       │   ├── sin_cos_cordic.v
│       │   └── func/atan_const.v
│       └── testbench/sin_cos_cordic_test.v
└── basic/
    └── mux/rtl/mux.v
```

Each arithmetic module has `rtl/<module>.v` and
`testbench/<module>_test.v`. ABS uses the ripple-carry adder and the basic mux;
the Makefile includes both dependencies. CORDIC's lookup function is included
from its own `rtl/func/` directory.

## Run the tests

Requirements: `iverilog` and `vvp`.

```sh
make -C regularity_modules test
make -C regularity_modules arithmetic_test
make -C regularity_modules basic_test

# Existing group and individual target names remain available.
make -C regularity_modules adder_test
make -C regularity_modules mul_test
make -C regularity_modules div_test
make -C regularity_modules mul_array
make -C regularity_modules mul_shift_add
make -C regularity_modules div_restoring
make -C regularity_modules abs
make -C regularity_modules sin_cos_cordic
```

`basic_test` compiles the mux. Its behavior is also exercised by the ABS tests.
Simulation outputs live in each module's `testbench/build/` and
`testbench/waves/` directories and are ignored by Git. For tests with optional
waveforms, pass `VVP_FLAGS=+dump` to make. Older generated outputs are retained
locally under ignored `regularity_modules/build/legacy/` and
`regularity_modules/waves/legacy/` directories.
