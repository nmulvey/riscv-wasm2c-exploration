# wasm2c sandboxing — disassembly analysis

**Toolchain**

- target: `riscv32-none-elf`
- compiler: `clang 21.1.8`
- ABI flags: `-march=rv32imafdc -mabi=ilp32d -mcmodel=medany`
- rtlib: `libgcc`
- id: `riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc`
- _resolved from: env vars where present, compiler query as fallback_

**Canonical pipeline flags** (from the Makefile)

- `WASM_CFLAGS` = `--target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all`
- `CFLAGS` = `-march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -g -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/arh6aqqgd8s6zhgha7ngs3rdwjd2gl7m-wabt-1.0.41/include -I/nix/store/q6kbnass9k9rdlh62rzpmjabf7by042a-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include`

---
## `loadptr`

- **Sandboxed focus symbol:** `w2c_loadptr_do_load` (C → wasm → wasm2c → native)
- **Native baseline symbol:** `do_load` (C → native, no WASM)
- **Configurations swept:** 12

### Sandboxed (wasm2c) disassembly

2 distinct disassembly groups.

#### Group 1 — 6 configs, 41 instructions

Configurations in this group (exact Make flags):

- `O2-strict-branches` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches`
- `O2-strict-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked`
- `O3-strict-branches` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches`
- `O3-strict-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked`
- `Os-strict-branches` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches`
- `Os-strict-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked`

```asm
addi sp, sp, -0x10
sw ra, 0xc(sp)
auipc a2, 0x0
lw a3, 0x0(a2)
addi a3, a3, 0x1
li a4, 0x1f5
sw a3, 0x0(a2)
bgeu a3, a4, 0x16 <.Lpcrel_hi1+0x12>
lw a4, 0x54(a0)
addi a3, a1, 0x4
sltu a5, a3, a1
beq a5, a4, 0x2e <.Lpcrel_hi1+0x2a>
sltu a3, a4, a5
j 0x34 <.Lpcrel_hi1+0x30>
lw a4, 0x50(a0)
sltu a3, a4, a3
bnez a3, 0x34 <.Lpcrel_hi1+0x30>
lw a0, 0x30(a0)
add a0, a0, a1
lbu a1, 0x1(a0)
lbu a3, 0x0(a0)
lbu a4, 0x2(a0)
lbu a0, 0x3(a0)
slli a1, a1, 0x8
or a1, a1, a3
slli a4, a4, 0x10
slli a0, a0, 0x18
or a0, a0, a4
or a0, a0, a1
lw a1, 0x0(a2)
addi a1, a1, -0x1
sw a1, 0x0(a2)
lw ra, 0xc(sp)
addi sp, sp, 0x10
ret
li a0, 0x1
auipc ra, 0x0
jalr ra <.Lpcrel_hi1+0x64>
li a0, 0xa
auipc ra, 0x0
jalr ra <.Lpcrel_hi1+0x6e>
```

#### Group 2 — 6 configs, 32 instructions

Configurations in this group (exact Make flags):

- `O2-unaligned-branches` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches`
- `O2-unaligned-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked`
- `O3-unaligned-branches` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches`
- `O3-unaligned-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked`
- `Os-unaligned-branches` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches`
- `Os-unaligned-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked`

```asm
addi sp, sp, -0x10
sw ra, 0xc(sp)
auipc a2, 0x0
lw a3, 0x0(a2)
addi a3, a3, 0x1
li a4, 0x1f5
sw a3, 0x0(a2)
bgeu a3, a4, 0x16 <.Lpcrel_hi1+0x12>
lw a4, 0x54(a0)
addi a3, a1, 0x4
sltu a5, a3, a1
beq a5, a4, 0x2e <.Lpcrel_hi1+0x2a>
sltu a3, a4, a5
j 0x34 <.Lpcrel_hi1+0x30>
lw a4, 0x50(a0)
sltu a3, a4, a3
bnez a3, 0x34 <.Lpcrel_hi1+0x30>
lw a0, 0x30(a0)
add a0, a0, a1
lw a0, 0x0(a0)
lw a1, 0x0(a2)
addi a1, a1, -0x1
sw a1, 0x0(a2)
lw ra, 0xc(sp)
addi sp, sp, 0x10
ret
li a0, 0x1
auipc ra, 0x0
jalr ra <.Lpcrel_hi1+0x4a>
li a0, 0xa
auipc ra, 0x0
jalr ra <.Lpcrel_hi1+0x54>
```

### Native baseline disassembly (no WASM)

1 distinct disassembly group.

#### Group 1 — 12 configs, 2 instructions

Configurations in this group (exact Make flags):

- `O2-strict-branches` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches`
- `O2-strict-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked`
- `O2-unaligned-branches` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches`
- `O2-unaligned-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked`
- `O3-strict-branches` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches`
- `O3-strict-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked`
- `O3-unaligned-branches` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches`
- `O3-unaligned-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked`
- `Os-strict-branches` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches`
- `Os-strict-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked`
- `Os-unaligned-branches` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches`
- `Os-unaligned-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked`

```asm
lw a0, 0x0(a0)
ret
```
