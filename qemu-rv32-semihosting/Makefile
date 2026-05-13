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
             -DWASM_RT_THREAD_LOCAL= \
             -MMD -MP
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

# `all` would otherwise be eclipsed as the default goal by the explicit rules
# defined below (e.g. crt0.o).
.DEFAULT_GOAL := all

# Disable built-in suffix/implicit rules so target selection is predictable.
.SUFFIXES:
MAKEFLAGS += --no-builtin-rules

TESTS       := $(notdir $(wildcard tests/*))
COMMON_OBJS := $(BUILD)/crt0.o $(BUILD)/wasm-rt-baremetal.o

# Per-test declarations. WASM_SOURCES_<test> lists *.c files under tests/<test>/
# that should be fed through the C->WASM->wasm2c pipeline. *.wat files are auto-
# discovered and always go through wat2wasm + wasm2c.
WASM_SOURCES_05_box := tweetnacl.c

# Per-source CFLAGS overrides.
#
# tweetnacl.c trips warnings, silence them only for that compilation step.
$(BUILD)/05_box/tweetnacl.o: CFLAGS += -Wno-sign-compare -Wno-error=unterminated-string-initialization

# crt0 and wasm-rt-baremetal are shared across all tests.
$(BUILD)/crt0.o: src/crt0.S
	mkdir -p $(dir $@)
	$(CC) $(ASFLAGS) -c $< -o $@

$(BUILD)/%.o: src/%.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# ------------------------------------------------------------------------------
# Per-test build rules.
#
# Stage 1 (codegen): produce *.wasm.c + *.wasm.h via wat2wasm/clang + wasm2c.
#
# Stage 2 (compile/link): native + wasm2c-generated objects are compiled to
# *.o, with an order-only dependency on stage 1 outputs so headers are in
# place before any test source #includes them.
#
# Entrypoints in tests/<test>/ are discovered as main.c and main_*.c. Each
# entrypoint becomes its own ELF + `qemu-*` target:
#   tests/<test>/main.c            -> build/<test>/<test>
#   tests/<test>/main_<suffix>.c   -> build/<test>/<test>_<suffix>
# ------------------------------------------------------------------------------

define TEST_RULES

# Per-test source enumeration.
$(1)_WAT_SRCS   := $$(wildcard tests/$(1)/*.wat)
$(1)_C_SRCS     := $$(wildcard tests/$(1)/*.c)
$(1)_ENTRY_SRCS := $$(filter tests/$(1)/main.c tests/$(1)/main_%.c,$$($(1)_C_SRCS))
$(1)_LIB_C_SRCS := $$(filter-out $$($(1)_ENTRY_SRCS),$$($(1)_C_SRCS))

# Stage 1 outputs: every *.wasm.c we'll produce for this test.
$(1)_STAGE1 := \
    $$(patsubst tests/$(1)/%.wat,$(BUILD)/$(1)/%.wasm.c,$$($(1)_WAT_SRCS)) \
    $$(patsubst %.c,$(BUILD)/$(1)/%.wasm.c,$$(WASM_SOURCES_$(1)))

# C -> WASM
$(BUILD)/$(1)/%.wasm: tests/$(1)/%.c
	mkdir -p $$(dir $$@)
	clang --target=wasm32 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all -o $$@ $$^

# WAT -> WASM
$(BUILD)/$(1)/%.wasm: tests/$(1)/%.wat
	mkdir -p $$(dir $$@)
	wat2wasm -o $$@ $$<

# WASM -> wasm2c (emits *.wasm.c and *.wasm.h together).
$(BUILD)/$(1)/%.wasm.c: $(BUILD)/$(1)/%.wasm
	mkdir -p $$(dir $$@)
	wasm2c -n $$(notdir $$*) -o $$@ $$<

# Native C -> object (from tests/<test>/).
#
# `$$(CFLAGS)` (deferred), target-specific overrides take effect at recipe time.
$(BUILD)/$(1)/%.o: tests/$(1)/%.c
	mkdir -p $$(dir $$@)
	$(CC) $$(CFLAGS) -I$(BUILD)/$(1) -c $$< -o $$@

# wasm2c-generated C -> object (from $(BUILD)/<test>/).
$(BUILD)/$(1)/%.o: $(BUILD)/$(1)/%.c
	mkdir -p $$(dir $$@)
	$(CC) $$(CFLAGS) -I$(BUILD)/$(1) -c $$< -o $$@

# Suppress wasm2c-specific warnings only on .wasm.o targets.
$(BUILD)/$(1)/%.wasm.o: CFLAGS += $$(WASM2C_CFLAGS)

# Object lists for this test:
#   <t>_NATIVE_OBJS : every tests/<t>/*.c compiled natively
#   <t>_WASM_OBJS   : every WAT- or WASM_SOURCES-derived *.wasm.o
$(1)_NATIVE_OBJS := $$(patsubst tests/$(1)/%.c,$(BUILD)/$(1)/%.o,$$($(1)_C_SRCS))
$(1)_WASM_OBJS   := $$(patsubst tests/$(1)/%.wat,$(BUILD)/$(1)/%.wasm.o,$$($(1)_WAT_SRCS)) \
                    $$(patsubst %.c,$(BUILD)/$(1)/%.wasm.o,$$(WASM_SOURCES_$(1)))

# Every stage-2 object in this test depends on stage-1 outputs (order-only:
# we just need the headers to exist, not to recompile every time .wasm.c
# regenerates — actual content dependencies come from -MMD).
$$($(1)_NATIVE_OBJS) $$($(1)_WASM_OBJS): | $$($(1)_STAGE1)

# Library objects shared by every entrypoint in this test: all non-entrypoint
# native objects plus all wasm2c-derived objects. The linker's --gc-sections
# drops anything unreferenced from the final ELF, so it's fine to feed every
# entrypoint the full set.
$(1)_LIB_OBJS := $$(patsubst tests/$(1)/%.c,$(BUILD)/$(1)/%.o,$$($(1)_LIB_C_SRCS)) \
                 $$($(1)_WASM_OBJS)

endef

# ------------------------------------------------------------------------------
# One ELF + qemu target per entrypoint per test.
# Parameters:
#   $(1) test name (e.g. 05_box)
#   $(2) entry stem (e.g. main, main_native)
#   $(3) ELF basename (e.g. 05_box, 05_box_native)
# ------------------------------------------------------------------------------
define ENTRY_RULE

$(BUILD)/$(1)/$(3): $(COMMON_OBJS) $(BUILD)/$(1)/$(2).o $$($(1)_LIB_OBJS)
	mkdir -p $$(dir $$@)
	$(CC) $(LDFLAGS) $$^ -o $$@
	@echo
	@$(SIZE) $$@

.PHONY: qemu-$(3)
qemu-$(3): $(BUILD)/$(1)/$(3)
	$(QEMU) -machine virt -bios none -nographic -semihosting -kernel $$<

ELFS += $(BUILD)/$(1)/$(3)

endef

# ------------------------------------------------------------------------------

# Compute the ELF basename for an entrypoint source path:
#   tests/<t>/main.c          -> <t>
#   tests/<t>/main_<suffix>.c -> <t>_<suffix>
elf_name = $(if $(filter main.c,$(notdir $(1))),$(2),$(2)_$(patsubst main_%.c,%,$(notdir $(1))))

ELFS :=
    $(foreach t,$(TESTS),$(eval $(call TEST_RULES,$(t))))
    $(foreach t,$(TESTS),$(foreach src,$($(t)_ENTRY_SRCS),\
        $(eval $(call ENTRY_RULE,$(t),$(basename $(notdir $(src))),$(call elf_name,$(src),$(t))))))

.PHONY: all clean
all: $(ELFS)

clean:
	rm -rf $(BUILD)

# Pick up header dependencies emitted by -MMD on prior builds.
-include $(shell find $(BUILD) -name '*.d' 2>/dev/null)
