# wasm2c sandboxing — disassembly analysis

**Toolchain**

- target: `riscv32-none-elf`
- compiler: `gcc 15.2.0`
- ABI flags: `-march=rv32imafdc -mabi=ilp32d -mcmodel=medany`
- rtlib: `libgcc`
- id: `riscv32-none-elf_gcc15.2.0_rv32imafdc-ilp32d-medany_libgcc`
- _resolved from: env vars where present, compiler query as fallback_

**Canonical pipeline flags** (from the Makefile)

- `WASM_CFLAGS` = `--target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all`
- `CFLAGS` = `-march=rv32imafdc -mabi=ilp32d -mcmodel=medany -O2 -g -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/arh6aqqgd8s6zhgha7ngs3rdwjd2gl7m-wabt-1.0.41/include -I/nix/store/q6kbnass9k9rdlh62rzpmjabf7by042a-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include`

---
## `loadptr`

- **Sandboxed focus symbol:** `w2c_loadptr_do_load` (C → wasm → wasm2c → native)
- **Native baseline symbol:** `do_load` (C → native, no WASM)
- **Configurations swept:** 12

### Sandboxed (wasm2c) disassembly

2 distinct disassembly groups.

#### Group 1 — 8 configs, 46 instructions

Configurations in this group (exact Make flags):

- `O2-strict-branches` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches`
- `O2-strict-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked`
- `O2-unaligned-branches` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches`
- `O2-unaligned-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked`
- `O3-strict-branches` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches`
- `O3-strict-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked`
- `O3-unaligned-branches` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches`
- `O3-unaligned-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked`

```asm
addi sp,sp,-32
sw s0,24(sp)
sw ra,28(sp)
addi s0,sp,32
auipc a4,0x0
lw a4,0(a4) # 8 <w2c_loadptr_do_load+0x8>
li a3,500
addi a5,a4,1
auipc a2,0x0
sw a5,0(a2) # 18 <w2c_loadptr_do_load+0x18>
bltu a3,a5,88 <.L16>
lw a3,84(a0)
addi a2,a1,4
sltu a5,a2,a1
bltu a3,a5,7e <.L14>
beq a3,a5,78 <.L17>
lw a5,48(a0)
add a1,a1,a5
lbu a0,0(a1)
lbu a2,1(a1)
lbu a3,2(a1)
lbu a5,3(a1)
sb a0,-20(s0)
sb a2,-19(s0)
sb a3,-18(s0)
sb a5,-17(s0)
lw a0,-20(s0)
lw ra,28(sp)
lw s0,24(sp)
auipc a5,0x0
sw a4,0(a5) # 62 <.L12+0x2c>
addi sp,sp,32
li a1,0
li a2,0
li a3,0
li a4,0
li a5,0
ret
lw a5,80(a0)
bgeu a5,a2,36 <.L12>
li a0,1
auipc ra,0x0
jalr ra # 80 <.L14+0x2>
li a0,10
auipc ra,0x0
jalr ra # 8a <.L16+0x2>
```

#### Group 2 — 4 configs, 44 instructions

Configurations in this group (exact Make flags):

- `Os-strict-branches` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches`
- `Os-strict-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked`
- `Os-unaligned-branches` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches`
- `Os-unaligned-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked`

```asm
addi sp,sp,-32
sw s0,24(sp)
sw s1,20(sp)
sw s2,16(sp)
sw ra,28(sp)
auipc s1,0x0
mv s1,s1
addi s0,sp,32
lw s2,0(s1) # a <w2c_loadptr_do_load+0xa>
li a4,500
addi a5,s2,1
sw a5,0(s1)
bgeu a4,a5,30 <.L9>
li a0,10
auipc ra,0x0
jalr ra # 28 <.L14>
lw a3,84(a0)
addi a5,a1,4
sltu a4,a5,a1
bltu a3,a4,48 <.L12>
bne a3,a4,4c <.L10>
lw a4,80(a0)
bgeu a4,a5,4c <.L10>
li a0,1
j 28 <.L14>
lw a5,48(a0)
li a2,4
addi a0,s0,-20
add a1,a1,a5
auipc ra,0x0
jalr ra # 56 <.L10+0xa>
lw a0,-20(s0)
lw ra,28(sp)
lw s0,24(sp)
sw s2,0(s1)
lw s1,20(sp)
lw s2,16(sp)
addi sp,sp,32
li a1,0
li a2,0
li a3,0
li a4,0
li a5,0
ret
```

### Native baseline disassembly (no WASM)

1 distinct disassembly group.

#### Group 1 — 12 configs, 9 instructions

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
addi sp,sp,-16
sw s0,8(sp)
sw ra,12(sp)
addi s0,sp,16
lw ra,12(sp)
lw s0,8(sp)
lw a0,0(a0)
addi sp,sp,16
ret
```
