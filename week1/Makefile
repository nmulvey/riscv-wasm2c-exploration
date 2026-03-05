# Week 1 - Native RISC-V vs wasm2c code size comparison (AES workload)
# Usage:
#   make native    # compile aes.c to native rv32imac
#   make wasm      # compile aes.c to wasm via WASI SDK
#   make wasm2c    # convert wasm to C and compile to rv32imac
#   make size      # compare sizes
#   make insns     # compare instruction counts
#   make all       # run everything
#   make clean     # remove generated files

WASI_SDK  = $(HOME)/wabt/wasi-sdk-24.0-arm64-macos
WASM2C    = $(HOME)/wabt/bin/wasm2c
CC_RISCV  = riscv64-unknown-elf-gcc
MARCH     = rv32imac_zicsr
MABI      = ilp32
RISCV_FLAGS = -O2 -march=$(MARCH) -mabi=$(MABI) -nostdlib -nostartfiles
WASI_FLAGS  = -O2 --sysroot=$(WASI_SDK)/share/wasi-sysroot

.PHONY: all native wasm wasm2c size insns clean

all: native wasm wasm2c size insns

# --- Native RISC-V ---
aes_native.o: aes.c aes.h
	$(CC_RISCV) $(RISCV_FLAGS) -I. -c aes.c -o aes_native.o

native: aes_native.o

# --- WebAssembly ---
aes.wasm: aes.c aes.h
	$(WASI_SDK)/bin/clang $(WASI_FLAGS) -I. -c aes.c -o aes.wasm

wasm: aes.wasm

# --- wasm2c -> RISC-V ---
aes_converted.c: aes.wasm
	$(WASM2C) aes.wasm -o aes_converted.c

aes_wasm2c.o: aes_converted.c wasm-rt.h
	$(CC_RISCV) $(RISCV_FLAGS) -I. -c aes_converted.c -o aes_wasm2c.o

wasm2c: aes_wasm2c.o

# --- Size comparison ---
size: native wasm2c
	@echo "\n=== Native RISC-V ==="
	@riscv64-unknown-elf-size aes_native.o
	@echo "\n=== wasm2c ==="
	@riscv64-unknown-elf-size aes_wasm2c.o

# --- Instruction counts ---
insns: native wasm2c
	@echo "\n=== Instruction counts: native vs wasm2c ==="
	@printf "%-12s %8s %8s\n" "Instruction" "Native" "wasm2c"
	@printf "%-12s %8s %8s\n" "lbu" \
		$$(riscv64-unknown-elf-objdump -d aes_native.o | grep -c "lbu") \
		$$(riscv64-unknown-elf-objdump -d aes_wasm2c.o | grep -c "lbu")
	@printf "%-12s %8s %8s\n" "bltu" \
		$$(riscv64-unknown-elf-objdump -d aes_native.o | grep -c "bltu") \
		$$(riscv64-unknown-elf-objdump -d aes_wasm2c.o | grep -c "bltu")
	@printf "%-12s %8s %8s\n" "bgeu" \
		$$(riscv64-unknown-elf-objdump -d aes_native.o | grep -c "bgeu") \
		$$(riscv64-unknown-elf-objdump -d aes_wasm2c.o | grep -c "bgeu")

# --- Clean ---
clean:
	rm -f aes_native.o aes.wasm aes_converted.c aes_converted.h aes_wasm2c.o
