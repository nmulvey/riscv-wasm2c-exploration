PROG=wasm2c_test
LIBFIVE_ROOT=../../libfive
include ../../libfive/rules.mk

ARCH=rv32imac_zicsr
LDFLAGS=-T ../../libfive/memmap.ld -L/usr/local/riscv64-unknown-elf/lib/rv32imac/ilp32 -L/usr/local/lib/gcc/riscv64-unknown-elf/13.2.0/rv32imac/ilp32 -melf32lriscv