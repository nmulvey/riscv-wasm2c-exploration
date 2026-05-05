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
             -Wall -Wextra -Wno-unused-parameter
ASFLAGS   := $(ARCHFLAGS)
LDFLAGS   := $(ARCHFLAGS) -nostartfiles  -T src/link.ld \
             -Wl,--no-warn-rwx-segments -Wl,--gc-sections \
             -specs=semihost.specs

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

COMMON_OBJS := $(BUILD)/crt0.o

.PHONY: all clean $(foreach t,$(TESTS),run-$(t))

all: $(ELFS)

$(BUILD)/crt0.o: src/crt0.S
	mkdir -p $(dir $@)
	$(CC) $(ASFLAGS) -c $< -o $@

$(BUILD)/%/main.o: tests/%/main.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

define TEST_RULES
$(BUILD)/$(1)/$(1): $(COMMON_OBJS) $(BUILD)/$(1)/main.o
	mkdir -p $$(dir $$@)
	$(CC) $(LDFLAGS) $$^ -o $$@
	@echo
	@$(SIZE) $$@

.PHONY: run-$(1)
run-$(1): $(BUILD)/$(1)/$(1)
	$(QEMU) -machine virt -bios none -nographic -semihosting -kernel $$<
endef

$(foreach t,$(TESTS),$(eval $(call TEST_RULES,$(t))))

clean:
	rm -rf $(BUILD)
