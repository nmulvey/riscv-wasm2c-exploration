# Bare-metal RISC-V32 hello-world for QEMU `virt`.
#
#   make           # build build/hello.elf
#   make run       # run it under qemu-system-riscv32 (semihosted, exits cleanly)
#   make clean
#
# Toolchain selection (override on the command line or in env):
#   CROSS_COMPILE  prefix for the cross toolchain. Auto-detected from the first
#                  of riscv32-none-elf-gcc / riscv64-unknown-elf-gcc on PATH.
#   MARCH/MABI     RISC-V arch and ABI. Defaults match the HiFive1 Rev B target
#                  Nicole has been using; the Nix devShell overrides to
#                  rv32gc/ilp32d to match the libc that nixpkgs ships.
#   QEMU           qemu-system-riscv32 binary.

ifndef CROSS_COMPILE
  ifneq (,$(shell command -v riscv32-none-elf-gcc 2>/dev/null))
    CROSS_COMPILE := riscv32-none-elf-
  else ifneq (,$(shell command -v riscv64-unknown-elf-gcc 2>/dev/null))
    CROSS_COMPILE := riscv64-unknown-elf-
  else
    $(error No RISC-V cross toolchain on PATH. Set CROSS_COMPILE or run `nix develop`.)
  endif
endif

CC      := $(CROSS_COMPILE)gcc
SIZE    := $(CROSS_COMPILE)size

MARCH ?= rv32imac
MABI  ?= ilp32
QEMU  ?= qemu-system-riscv32

BUILD := build

ARCHFLAGS := -march=$(MARCH) -mabi=$(MABI) -mcmodel=medany
CFLAGS    := $(ARCHFLAGS) -O2 -g -ffunction-sections -fdata-sections \
             -Wall -Wextra -Wno-unused-parameter
ASFLAGS   := $(ARCHFLAGS)
LDFLAGS   := $(ARCHFLAGS) -nostartfiles -T link.ld \
             -Wl,--gc-sections -Wl,-Map=$(BUILD)/hello.map \
             -specs=semihost.specs

OBJS  := $(BUILD)/crt0.o $(BUILD)/main.o
ELF   := $(BUILD)/hello.elf

.PHONY: all run clean

all: $(ELF)

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/%.o: src/%.S | $(BUILD)
	$(CC) $(ASFLAGS) -c $< -o $@

$(BUILD)/%.o: src/%.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(ELF): $(OBJS) link.ld | $(BUILD)
	$(CC) $(LDFLAGS) $(OBJS) -o $@
	@echo
	@$(SIZE) $@

run: $(ELF)
	$(QEMU) -machine virt -bios none -nographic -semihosting -kernel $(ELF)

clean:
	rm -rf $(BUILD)
