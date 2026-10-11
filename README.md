# Regularity Modules

Verilog implementations and tests for arithmetic and basic logic modules.
Multiple implementations share a family folder; single implementations live
directly in their category. All testbenches are collected in `test/`.

```text
regularity_modules/
├── Makefile
├── arithmetic/
│   ├── abs.v
│   ├── comparator.v
│   ├── div_restoring.v
│   ├── sin_cos_cordic.v
│   ├── adder/
│   │   ├── adder_carry_save.v
│   │   ├── adder_carry_skip.v
│   │   └── adder_ripple_carry.v
│   ├── mul/
│   │   ├── mul_array.v
│   │   └── mul_shift_add.v
│   └── func/atan_const.v
├── basic/
│   └── mux.v
└── test/
    ├── abs_test.v
    ├── adder_carry_save_test.v
    ├── adder_carry_skip_test.v
    ├── adder_ripple_carry_test.v
    ├── comparator_test.v
    ├── div_restoring_test.v
    ├── mul_array_test.v
    ├── mul_shift_add_test.v
    └── sin_cos_cordic_test.v
```

ABS uses the ripple-carry adder and the basic mux; the Makefile includes both
dependencies. CORDIC includes its lookup function from `arithmetic/func/`.

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
Simulation outputs live in `regularity_modules/test/build/` and
`regularity_modules/test/waves/` and are ignored by Git. For tests with optional
waveforms, pass `VVP_FLAGS=+dump` to make. Older generated outputs are retained
locally in the `legacy/` subfolders of those output directories.
