PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ARITHMETIC_DIR := $(PROJECT_DIR)arithmetic
BASIC_DIR := $(PROJECT_DIR)basic

IVERILOG = iverilog
VVP = vvp
VVP_FLAGS ?=

ARITHMETIC_MODULES := adder_ripple_carry adder_carry_save adder_carry_skip mul_shift_add mul_array div_restoring comparator abs sin_cos_cordic

.DEFAULT_GOAL := test
.PHONY: test arithmetic_test basic_test adder_test mul_test div_test comparator_test $(ARITHMETIC_MODULES) mux

test: arithmetic_test basic_test
arithmetic_test: $(ARITHMETIC_MODULES)
basic_test: mux
adder_test: adder_ripple_carry adder_carry_save adder_carry_skip
mul_test: mul_shift_add mul_array
div_test: div_restoring
comparator_test: comparator

# The existing ripple-carry testbench uses the top module name adder_test.
adder_ripple_carry_TOP := adder_test
abs_SOURCES := $(ARITHMETIC_DIR)/adder_ripple_carry/rtl/adder_ripple_carry.v $(BASIC_DIR)/mux/rtl/mux.v
sin_cos_cordic_HEADERS := $(ARITHMETIC_DIR)/sin_cos_cordic/rtl/func/atan_const.v

# Run from the module directory so each testbench writes its own waveforms.
define ARITHMETIC_TEST
$(1): $(ARITHMETIC_DIR)/$(1)/rtl/$(1).v $(ARITHMETIC_DIR)/$(1)/testbench/$(1)_test.v $$($(1)_SOURCES) $$($(1)_HEADERS)
	mkdir -p $(ARITHMETIC_DIR)/$(1)/testbench/build $(ARITHMETIC_DIR)/$(1)/testbench/waves
	$$(IVERILOG) -g2012 -I$(ARITHMETIC_DIR)/$(1)/rtl -s $$(if $$($(1)_TOP),$$($(1)_TOP),$(1)_test) -o $(ARITHMETIC_DIR)/$(1)/testbench/build/$(1) $(ARITHMETIC_DIR)/$(1)/testbench/$(1)_test.v $(ARITHMETIC_DIR)/$(1)/rtl/$(1).v $$($(1)_SOURCES)
	cd $(ARITHMETIC_DIR)/$(1) && $$(VVP) testbench/build/$(1) $$(VVP_FLAGS)
endef
$(foreach module,$(ARITHMETIC_MODULES),$(eval $(call ARITHMETIC_TEST,$(module))))

# Mux has no standalone testbench; compile it here and exercise it in abs_test.
mux: $(BASIC_DIR)/mux/rtl/mux.v
	$(IVERILOG) -g2012 -s mux -tnull $<
