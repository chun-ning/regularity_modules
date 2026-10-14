PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ARITHMETIC_DIR := $(PROJECT_DIR)arithmetic
BASIC_DIR := $(PROJECT_DIR)basic
TEST_DIR := $(PROJECT_DIR)test
BUILD_DIR := $(TEST_DIR)/build
WAVE_DIR := $(TEST_DIR)/waves

IVERILOG = iverilog
VVP = vvp
VVP_FLAGS ?=

ARITHMETIC_MODULES := adder_ripple_carry adder_carry_save adder_carry_skip mul_shift_add mul_array div_restoring comparator abs sin_cos_cordic log2

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
abs_SOURCES := $(ARITHMETIC_DIR)/adder/adder_ripple_carry.v $(BASIC_DIR)/mux.v
sin_cos_cordic_HEADERS := $(ARITHMETIC_DIR)/func/atan_const.v

# Group multiple implementations; single implementations live in arithmetic/.
$(foreach module,$(ARITHMETIC_MODULES),$(eval $(module)_RTL := $(ARITHMETIC_DIR)/$(module).v))
$(foreach module,adder_ripple_carry adder_carry_save adder_carry_skip,$(eval $(module)_RTL := $(ARITHMETIC_DIR)/adder/$(module).v))
$(foreach module,mul_shift_add mul_array,$(eval $(module)_RTL := $(ARITHMETIC_DIR)/mul/$(module).v))

# Comparator resides in basic/ after the category move.
comparator_RTL := $(BASIC_DIR)/comparator.v

# All testbenches run from the project root and share test/build and test/waves.
define ARITHMETIC_TEST
$(1): $$($(1)_RTL) $(TEST_DIR)/$(1)_test.v $$($(1)_SOURCES) $$($(1)_HEADERS)
	mkdir -p $(BUILD_DIR) $(WAVE_DIR)
	$$(IVERILOG) -g2012 -I$(ARITHMETIC_DIR) -s $$(if $$($(1)_TOP),$$($(1)_TOP),$(1)_test) -o $(BUILD_DIR)/$(1) $(TEST_DIR)/$(1)_test.v $$($(1)_RTL) $$($(1)_SOURCES)
	cd $(PROJECT_DIR) && $$(VVP) $(BUILD_DIR)/$(1) $$(VVP_FLAGS)
endef
$(foreach module,$(ARITHMETIC_MODULES),$(eval $(call ARITHMETIC_TEST,$(module))))

# Mux has no standalone testbench; compile it here and exercise it in abs_test.
mux: $(BASIC_DIR)/mux.v
	$(IVERILOG) -g2012 -s mux -tnull $<
