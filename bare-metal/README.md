# bare-metal: wasm2c on rv32 RISC-V, no OS

Minimal bare-metal runtime for wasm2c-compiled code running in QEMU. No OS, no libc, no guard pages with a static heap, UART output, wasm2c generated code.

## Files
- `crt0.S` — sets stack pointer, initializes UART, calls `main`
- `link.ld` — places binary at `0x80000000` (QEMU virt load address)
- `wasm-rt-baremetal.c` — minimal wasm2c runtime, replaces `wasm-rt-impl.h`
- `wasm-rt.h` — modified for baremetal 
- `main_fixed.c` — instantiates and calls the wasm module
- `constant.c` / `constant.h` — wasm2c output from `constant.wasm`

## Build

```bash
/usr/local/Cellar/riscv-gnu-toolchain/main/bin/riscv64-unknown-elf-gcc \
  -g -march=rv32imac_zicsr -mabi=ilp32 \
  -nostartfiles -nostdlib -ffreestanding \
  -DWASM_RT_NONCONFORMING_UNCHECKED_STACK_EXHAUSTION=1 \
  -T link.ld \
  -o wasm2c_test \
  crt0.S main_fixed.c constant.c wasm-rt-baremetal.c \
  -lm -lc -lgcc
```

## Run

```bash
qemu-system-riscv32 -machine virt -bios none -nographic -kernel wasm2c_test
```

## Output

```
Starting wasm2c test
runtime init done
instantiate done
wasm2c result: 42
```

## Notes

- **No TLS** — bare metal has no `tp` set up, so thread-local stack depth tracking is disabled via `-DWASM_RT_NONCONFORMING_UNCHECKED_STACK_EXHAUSTION=1`
- **Static heap** — no `malloc`/`calloc`; uses `static uint8_t heap[65536]`
- **UART** — writes directly to `0x10000000` (ns16550 on QEMU virt)
- **No `wasm_rt_grow_memory`** — always returns failure

## Debugging

```bash
# QEMU with GDB stub
qemu-system-riscv32 -machine virt -bios none -nographic -kernel wasm2c_test -S -gdb tcp::1234

```

Jump to `0x00000000` --> null pointer or uninitialized `tp`. Common culprits: newlib stdio (`-nostdlib` fixes it), LSR busy-wait hang (write directly to UART base), `calloc` on bare metal (use static buffer).
