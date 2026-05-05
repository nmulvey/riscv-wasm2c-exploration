ifndef TOOLCHAIN_PREFIX
  ifneq (,$(shell command -v riscv32-none-elf-gcc 2>/dev/null))
    TOOLCHAIN_PREFIX := riscv32-none-elf-
  else ifneq (,$(shell command -v riscv64-unknown-elf-gcc 2>/dev/null))
    TOOLCHAIN_PREFIX := riscv64-unknown-elf-
  else
    $(error No RISC-V cross toolchain on PATH. Set TOOLCHAIN_PREFIX or run `nix develop`.)
  endif
endif

CC   := $(TOOLCHAIN_PREFIX)gcc
SIZE := $(TOOLCHAIN_PREFIX)size

MARCH ?= rv32imac
MABI  ?= ilp32
QEMU  ?= qemu-system-riscv32

BUILD := build

ARCHFLAGS := -march=$(MARCH) -mabi=$(MABI) -mcmodel=medany
CFLAGS    := $(ARCHFLAGS) -O2 -g -ffunction-sections -fdata-sections \
             -Wall -Wextra -Werror \
             -DWASM_RT_THREAD_LOCAL= # Don't use _Thread_local
ASFLAGS   := $(ARCHFLAGS)
LDFLAGS   := $(ARCHFLAGS) -nostartfiles  -T src/link.ld \
             -Wl,--no-warn-rwx-segments -Wl,--gc-sections \
             -specs=semihost.specs
# Warnings to suppress when compiling wasm2c-generated C. Applied via a
# target-specific variable on %.wasm.o below.
WASM2C_CFLAGS := -Wno-unused-variable -Wno-unused-function \
                 -Wno-unused-value -Wno-unused-parameter

# The user may pass `NEWLIB_PREFIX` to force compiling and linking against a
# custom newlib libc build. This is useful when the system one isn't compiled
# with the right options, or the compiler isn't built with a multilib newlib.
ifdef NEWLIB_PREFIX
    CFLAGS  += -nolibc \
               -I$(NEWLIB_PREFIX)/riscv32-none-elf/include
    LDFLAGS += -L$(NEWLIB_PREFIX)/riscv32-none-elf/lib \
               -lc -lsemihost
endif

TESTS := $(notdir $(wildcard tests/*))
ELFS  := $(foreach t,$(TESTS),$(BUILD)/$(t)/$(t))

COMMON_OBJS := $(BUILD)/crt0.o $(BUILD)/wasm-rt-baremetal.o

.PHONY: all clean $(foreach t,$(TESTS),run-$(t))

all: $(ELFS)

$(BUILD)/crt0.o: src/crt0.S
	mkdir -p $(dir $@)
	$(CC) $(ASFLAGS) -c $< -o $@

$(BUILD)/%.o: src/%.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

define TEST_RULES
# WAT -> WASM
$(BUILD)/$(1)/%.wasm: tests/$(1)/%.wat
	mkdir -p $$(dir $$@)
	wat2wasm $$^ -o $$@

# WASM -> wasm2c
$(BUILD)/$(1)/%.wasm.c: $(BUILD)/$(1)/%.wasm
	mkdir -p $$(dir $$@)
	wasm2c $$^ -o $$@

# C -> object (from tests/)
$(BUILD)/$(1)/%.o: tests/$(1)/%.c
	mkdir -p $$(dir $$@)
	$(CC) $(CFLAGS) -I$(BUILD)/$(1) -c $$< -o $$@

# C -> object (from $(BUILD)/, e.g. wasm2c output).
# CFLAGS is referenced with $$ so the lookup is deferred to recipe time,
# letting the target-specific override on %.wasm.o below take effect.
$(BUILD)/$(1)/%.o: $(BUILD)/$(1)/%.c
	mkdir -p $$(dir $$@)
	$(CC) $$(CFLAGS) -c $$< -o $$@

# Suppress wasm2c-specific warnings only on .wasm.o targets.
$(BUILD)/$(1)/%.wasm.o: CFLAGS += $$(WASM2C_CFLAGS)

# Force every test C object to wait for all wasm2c outputs in this test.
# wasm2c emits the .wasm.h alongside the .wasm.c, so depending on the .c
# guarantees the header exists before any test source #includes it,
# regardless of which file in tests/$(1) actually pulls it in.
$(1)_WASM_C    := $$(patsubst tests/$(1)/%.wat,$(BUILD)/$(1)/%.wasm.c,$$(wildcard tests/$(1)/*.wat))
$(1)_TEST_OBJS := $$(patsubst tests/$(1)/%.c,$(BUILD)/$(1)/%.o,$$(wildcard tests/$(1)/*.c))
$$($(1)_TEST_OBJS): $$($(1)_WASM_C)

# Final test ELF, named after the test. Per-test extras can be added by
# setting EXTRA_OBJS_<testname> before this rule is generated.
$(BUILD)/$(1)/$(1): $(COMMON_OBJS) $(BUILD)/$(1)/main.o $$(EXTRA_OBJS_$(1))
	mkdir -p $$(dir $$@)
	$(CC) $(LDFLAGS) $$^ -o $$@
	@echo
	@$(SIZE) $$@

# QEMU target:
.PHONY: run-$(1)
qemu-$(1): $(BUILD)/$(1)/$(1)
	$(QEMU) -machine virt -bios none -nographic -semihosting -kernel $$<
endef

EXTRA_OBJS_01_constant := $(BUILD)/01_constant/constant.wasm.o

$(foreach t,$(TESTS),$(eval $(call TEST_RULES,$(t))))

clean:
	rm -rf $(BUILD)
