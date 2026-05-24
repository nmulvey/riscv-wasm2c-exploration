# Which ISA family this build targets. Each family fills in its own defaults
# below (compiler prefix, ARCHFLAGS, linker script, QEMU machine, etc.).
# Add a family by extending the block below (and providing matching crt0/
# linker script under src/).
ARCH_FAMILY ?= riscv32

# By default, we try to find a gcc toolchain for compiling to the chosen
# target family. Set USE_CLANG=1 to use `clang` for compiling and linking
# instead. The ARM and RISC-V paths both support clang.
USE_CLANG ?= 0

# Runtime helper library for the clang path (compiler ABI helpers like
# __mulsi3, __ashldi3, etc.). Only consulted when USE_CLANG=1.
#   libgcc       (default): link gcc's libgcc.a. Always available since
#                newlib is built with gcc.
#   compiler-rt: link clang's compiler-rt builtins. Requires
#                COMPILER_RT_BUILTINS=/path/to/libclang_rt.builtins-<arch>.a
#                (nixpkgs's clang doesn't ship one for bare-metal targets;
#                the flake builds it on demand for the *-clang-rt variants).
RTLIB ?= libgcc

# --- Per-family defaults -------------------------------------------------
# Variables filled in here:
#   TARGET_TRIPLE  : sysroot subdir under NEWLIB_PREFIX
#   ABIFLAGS       : multilib/ABI selection flags accepted by *both* gcc and
#                    clang for this family (-march/-mabi on RISC-V,
#                    -mcpu/-mthumb/-mfloat-abi/-mfpu on ARM). Used as-is when
#                    invoking $(TOOLCHAIN_PREFIX)gcc to query libgcc.
#   CLANG_TARGET   : value for clang's --target= (USE_CLANG=1 only). Not in
#                    ABIFLAGS because gcc doesn't understand --target=.
#   SEMIHOST_SPECS : newlib specs file for the gcc path (semihost.specs / rdimon.specs)
#   SEMIHOST_LIB   : libc helper for the clang path (-lsemihost / -lrdimon)
#   CRT0_SRC       : assembly entrypoint compiled into $(BUILD)/crt0.o
#   LINK_SCRIPT    : board-specific linker script
#   QEMU_SYSTEM    : qemu binary
#   QEMU_MACHINE   : -machine value
#   QEMU_EXTRA     : extra flags (e.g. RISC-V virt needs -bios none)
#   TOOLCHAIN_TRIPLES : list of binutils prefixes to probe when
#                       TOOLCHAIN_PREFIX is not set
ifeq ($(ARCH_FAMILY),riscv32)
  TARGET_TRIPLE     ?= riscv32-none-elf
  MARCH             ?= rv32imac
  MABI              ?= ilp32
  ABIFLAGS          := -march=$(MARCH) -mabi=$(MABI) -mcmodel=medany
  CLANG_TARGET      ?= riscv32-none-elf
  SEMIHOST_SPECS    ?= semihost.specs
  SEMIHOST_LIB      ?= -lsemihost
  CRT0_SRC          ?= src/crt0.S
  LINK_SCRIPT       ?= src/link.ld
  QEMU_SYSTEM       ?= qemu-system-riscv32
  QEMU_MACHINE      ?= virt
  QEMU_EXTRA        ?= -bios none
  TOOLCHAIN_TRIPLES := riscv32-none-elf- riscv64-unknown-elf-
else ifeq ($(ARCH_FAMILY),arm)
  TARGET_TRIPLE     ?= arm-none-eabi
  MCPU              ?= cortex-m4
  MTHUMB            ?= 1
  MFLOAT_ABI        ?= hard
  MFPU              ?= fpv4-sp-d16
  ABIFLAGS          := -mcpu=$(MCPU) -mfloat-abi=$(MFLOAT_ABI)
  ifeq ($(MTHUMB),1)
    ABIFLAGS        += -mthumb
  endif
  ifneq ($(MFPU),)
    ABIFLAGS        += -mfpu=$(MFPU)
  endif
  CLANG_TARGET      ?= thumbv7em-none-eabihf
  SEMIHOST_SPECS    ?= rdimon.specs
  SEMIHOST_LIB      ?= -lrdimon
  CRT0_SRC          ?= src/crt0_arm_v7m.S
  LINK_SCRIPT       ?= src/link_mps2_an386.ld
  QEMU_SYSTEM       ?= qemu-system-arm
  QEMU_MACHINE      ?= mps2-an386
  QEMU_EXTRA        ?=
  TOOLCHAIN_TRIPLES := arm-none-eabi-
else
  $(error Unknown ARCH_FAMILY=$(ARCH_FAMILY). Valid: riscv32, arm.)
endif
# -------------------------------------------------------------------------

# Probe TOOLCHAIN_TRIPLES for a usable binutils prefix. Used unconditionally
# for `size` / `gdb` fallbacks; also used as the C compiler prefix in the
# gcc path.
ifndef TOOLCHAIN_PREFIX
  TOOLCHAIN_PREFIX := $(firstword $(foreach t,$(TOOLCHAIN_TRIPLES),\
                       $(if $(shell command -v $(t)gcc 2>/dev/null),$(t))))
  ifeq ($(TOOLCHAIN_PREFIX),)
    ifneq ($(USE_CLANG),1)
      $(error No $(ARCH_FAMILY) cross toolchain on PATH (looked for: $(TOOLCHAIN_TRIPLES)gcc). Set TOOLCHAIN_PREFIX or run `nix develop`.)
    endif
  endif
endif

ifeq ($(USE_CLANG),1)
  CC     := clang
  SIZE   := llvm-size
else
  CC     := $(TOOLCHAIN_PREFIX)gcc
  SIZE   := $(TOOLCHAIN_PREFIX)size
endif


# Always use clang to compile C -> WASM
WASM_CC  := clang

GDB      ?= $(shell command -v $(TOOLCHAIN_PREFIX)gdb 2>/dev/null || echo gdb)

QEMU     ?= $(QEMU_SYSTEM)
GDB_PORT ?= 1234

BUILD := build

# Flags for the C -> native compilation steps. ABIFLAGS comes from the
# per-family block above; we splice in --target= only for the clang path
# (gcc doesn't accept --target=, which is why the libgcc lookup below
# uses ABIFLAGS directly rather than ARCHFLAGS).
ARCHFLAGS := $(ABIFLAGS)
ifeq ($(USE_CLANG),1)
  ARCHFLAGS += --target=$(CLANG_TARGET)
endif

CFLAGS    := $(ARCHFLAGS) -O2 -g -ffunction-sections -fdata-sections \
             -Wall -Wextra -Werror \
             -Isrc \
             -DWASM_RT_THREAD_LOCAL= \
             -MMD -MP
ifdef WABT_INCLUDE
  CFLAGS  += -I$(WABT_INCLUDE)
endif

ASFLAGS   := $(ARCHFLAGS)

LDFLAGS   := $(ARCHFLAGS) -nostartfiles  -T $(LINK_SCRIPT) \
             -Wl,--gc-sections

# Libraries appended AFTER object files at link time. GNU make's standard
# slot for this is LDLIBS — order matters because archives only contribute
# symbols that are still unresolved when the linker reaches them.
LDLIBS    :=

ifeq ($(USE_CLANG),1)
  LDFLAGS += -fuse-ld=lld
  # Clang has no equivalent of GCC's -specs={semihost,rdimon}.specs, which
  # transparently pulls in libc + the semihost stubs. The user must supply
  # a newlib build via NEWLIB_PREFIX so we can link -lc + $(SEMIHOST_LIB)
  # explicitly via LDLIBS below.
  ifndef NEWLIB_PREFIX
    $(error USE_CLANG=1 requires NEWLIB_PREFIX (clang has no semihost-specs equivalent). Run via `nix develop` or set NEWLIB_PREFIX.)
  endif
else
  LDFLAGS += -specs=$(SEMIHOST_SPECS) -Wl,--no-warn-rwx-segments
endif

# Flags for the C -> WASM compilation steps:
WASM_CFLAGS   :=  --target=wasm32 -O3 -nostdlib -fuse-ld=lld \
                  -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all

# Warnings to suppress when compiling wasm2c-generated C. Applied via a
# target-specific variable on %.wasm.o below.
WASM2C_CFLAGS := -Wno-unused-variable -Wno-unused-function \
                 -Wno-unused-value -Wno-unused-parameter

# ---- Optimization ablation knobs ---------------------------------------------
# Toggle individually on the command line (e.g. `make LTO=1 O3_WASM=1`).
# Defaults preserve the project baseline (no extra optimization, no timing).
# `make clean` between toggles is recommended so every TU is rebuilt with the
# new flag set.
LTO         ?= 0  # -flto on compile + link
O3_WASM     ?= 0  # -O3 on %.wasm.o only (-O2 otherwise)
OS          ?= 0  # -Os appended globally (last -O wins, so size-optimized)
OS_WASM     ?= 0  # -Os on %.wasm.o only
UNROLL_WASM ?= 0  # -funroll-loops on %.wasm.o
DEBUG       ?= 1  # -g (default on); DEBUG=0 strips debug info
BENCH       ?= 0  # -DBENCH, enables cycle/instret timing in main_*.c
NO_STRICT_ALIGN ?= 0 # -mno-strict-align


ifeq ($(LTO),1)
    CFLAGS  += -flto
    LDFLAGS += -flto
endif

ifeq ($(DEBUG),0)
    CFLAGS := $(filter-out -g,$(CFLAGS))
endif

ifeq ($(O3_WASM),1)
    WASM2C_CFLAGS += -O3
endif

ifeq ($(OS),1)
    CFLAGS += -Os
endif

ifeq ($(OS_WASM),1)
    WASM2C_CFLAGS += -Os
endif

ifeq ($(UNROLL_WASM),1)
    WASM2C_CFLAGS += -funroll-loops
endif

ifeq ($(BENCH),1)
    CFLAGS += -DBENCH
endif
ifeq ($(NO_STRICT_ALIGN),1)
  # RISC-V toolchains spell "allow misaligned access" as -mno-strict-align.
  # ARM Cortex-M (M3+) supports misaligned access by default; -munaligned-access
  # is GCC's positive spelling. The knob is a no-op on families where unaligned
  # access is already the default.
  ifeq ($(ARCH_FAMILY),riscv32)
    CFLAGS += -mno-strict-align
  else ifeq ($(ARCH_FAMILY),arm)
    CFLAGS += -munaligned-access
  endif
endif
# ------------------------------------------------------------------------------

# The user may pass `NEWLIB_PREFIX` to force compiling and linking against a
# custom newlib libc build. This is useful when the system one isn't compiled
# with the right options, or the compiler isn't built with a multilib newlib.
#
# `NEWLIB_LIBDIR` overrides the lib search path. Defaults to the top-level
# $(NEWLIB_PREFIX)/$(TARGET_TRIPLE)/lib, which is correct for single-multilib
# toolchains (e.g. the nixpkgs riscv32 cross — `--disable-multilib`). Multilib
# toolchains where the top-level lib holds the wrong ABI (e.g. gcc-arm-embedded,
# whose top-level lib is armv4t soft-float) must override this with the matching
# subdirectory (e.g. arm-none-eabi/lib/thumb/v7e-m+fp/hard).
ifdef NEWLIB_PREFIX
  CFLAGS    += -I$(NEWLIB_PREFIX)/$(TARGET_TRIPLE)/include
  NEWLIB_LIBDIR ?= $(NEWLIB_PREFIX)/$(TARGET_TRIPLE)/lib
  LDFLAGS   += -L$(NEWLIB_LIBDIR)
  # gcc with -specs=$(SEMIHOST_SPECS) auto-pulls libc + the semihost stub
  # from -L paths; clang has no such mechanism, so request them explicitly.
  # These go in LDLIBS so they appear after the objects on the link line.
  ifeq ($(USE_CLANG),1)
    LDLIBS += -lc $(SEMIHOST_LIB)
  endif
endif

# Wire up the chosen RTLIB for the clang path.
ifeq ($(USE_CLANG),1)
  ifeq ($(RTLIB),libgcc)
    # The libgcc.a we pick must match MARCH/MABI. Two ways to find it:
    #   - LIBGCC_PATH: set by the caller (the flake passes it as a direct
    #     store path so the clang build doesn't need gcc on PATH).
    #   - Otherwise: shell out to `gcc -print-libgcc-file-name`, which
    #     requires $(TOOLCHAIN_PREFIX)gcc on PATH (standalone fallback).
    ifdef LIBGCC_PATH
      LIBGCC := $(LIBGCC_PATH)
    else
      # ABIFLAGS (-march/-mabi on RISC-V; -mcpu/-mthumb/-mfloat-abi/-mfpu on
      # ARM) is the multilib-selecting subset of ARCHFLAGS, and is exactly
      # what gcc consults to resolve the libgcc directory. ARCHFLAGS itself
      # may carry --target= under USE_CLANG=1, which gcc rejects, so don't
      # pass it here.
      LIBGCC := $(shell $(TOOLCHAIN_PREFIX)gcc $(ABIFLAGS) -print-libgcc-file-name 2>/dev/null)
    endif
    ifeq ($(LIBGCC),)
      $(error Could not locate libgcc.a. Set LIBGCC_PATH=/path/to/libgcc.a, or ensure `$(TOOLCHAIN_PREFIX)gcc` is on PATH.)
    endif
    LDFLAGS += --rtlib=libgcc -L$(dir $(LIBGCC))
    # clang's ARM driver auto-adds `-lgcc_s` (or `-lgcc_eh` under -static),
    # which gcc-arm-embedded doesn't ship — link fails with "unable to find
    # library -lgcc_s". `--unwindlib=none` strips that out and leaves just
    # `-lgcc -lc`. Harmless on RISC-V where the driver wasn't adding it
    # anyway (no exception-unwinding multilib for riscv32-none-elf).
    LDFLAGS += --unwindlib=none
  else ifeq ($(RTLIB),compiler-rt)
    ifdef COMPILER_RT_BUILTINS
      # nixpkgs's clang doesn't ship libclang_rt.builtins for bare-metal
      # riscv32, so the caller must point at a prebuilt archive (the flake's
      # *-clang-rt variants build it via `compilerRtBuiltinsFor` and pass the
      # path here). We link the archive directly so we don't depend on clang's
      # resource-dir search. If we provide this, we have to pass
      # `-nodefaultlibs` too:
      LDFLAGS += -nodefaultlibs
      LDLIBS += $(COMPILER_RT_BUILTINS)
    else
      LDFLAGS += -rtlib=compiler-rt
    endif
  else
    $(error Unknown RTLIB=$(RTLIB). Valid: libgcc, compiler-rt.)
  endif
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

# crt0 and wasm-rt-baremetal are shared across all tests. The crt0 source
# comes from $(CRT0_SRC) — set by ARCH_FAMILY above (src/crt0.S on RISC-V,
# src/crt0_arm_v7m.S on ARM).
$(BUILD)/crt0.o: $(CRT0_SRC)
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
	$(WASM_CC) $(WASM_CFLAGS) -o $$@ $$^

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
	$(CC) $(LDFLAGS) $$^ $(LDLIBS) -o $$@
	@echo
	@$(SIZE) $$@

.PHONY: qemu-$(3) qemu-gdb-$(3) gdb-$(3)

qemu-$(3): $(BUILD)/$(1)/$(3)
	$(QEMU) -machine $(QEMU_MACHINE) -icount shift=0 $(QEMU_EXTRA) -nographic -semihosting -kernel $$<

# `qemu-gdb-<elf>` runs QEMU with the CPU halted at reset and a gdbserver
# listening on $(GDB_PORT). Use with `gdb-<elf>` from a second terminal.
qemu-gdb-$(3): $(BUILD)/$(1)/$(3)
	$(QEMU) -machine $(QEMU_MACHINE) -icount shift=0 $(QEMU_EXTRA) -nographic -semihosting -kernel $$< \
	    -gdb tcp::$(GDB_PORT) -S

# `gdb-<elf>` prints the gdb invocation and writes a per-ELF .gdbinit.
$(BUILD)/$(1)/$(3).gdbinit: $(BUILD)/$(1)/$(3)
	@printf 'file %s\ntarget remote localhost:$(GDB_PORT)\n' '$$<' > $$@

gdb-$(3): $(BUILD)/$(1)/$(3).gdbinit
	@echo
	@echo "Start QEMU in another terminal:"
	@echo "    make qemu-gdb-$(3)"
	@echo
	@echo "Then attach gdb:"
	@echo "    $(GDB) -x $$<"
	@echo
	@echo "Or source $$< from an already-running gdb session."

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
