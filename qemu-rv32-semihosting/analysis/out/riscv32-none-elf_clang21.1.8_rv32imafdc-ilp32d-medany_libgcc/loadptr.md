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
- `CFLAGS` = `-march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -g -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include`

---
## `loadptr`

- **Sandboxed focus symbol:** `w2c_loadptr_do_load` (C → wasm → wasm2c → native)
- **Native baseline symbol:** `do_load` (C → native, no WASM)
- **Configurations swept:** 12

### Sandboxed (wasm2c) disassembly

4 distinct disassembly groups.

#### Group 1 — 3 configs, 41 instructions

Configurations in this group (exact Make flags):

- `O2-strict-branches` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches`
- `O3-strict-branches` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches`
- `Os-strict-branches` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches`

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

<details>
<summary>Build output (3 <code>make</code> invocations, stdout &amp; stderr)</summary>

```
$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-branches DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-branches
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-branches/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-branches/loadptr.wasm.c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-branches/loadptr.wasm
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=1 -O2 -Ibuild/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-branches \
    -c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-branches/loadptr.wasm.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-branches/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-branches DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-branches
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-branches/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-branches/loadptr.wasm.c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-branches/loadptr.wasm
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=1 -O3 -Ibuild/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-branches \
    -c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-branches/loadptr.wasm.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-branches/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-branches DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-branches
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-branches/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-branches/loadptr.wasm.c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-branches/loadptr.wasm
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=1 -Os -Ibuild/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-branches \
    -c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-branches/loadptr.wasm.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-branches/loadptr.wasm.o
--- stderr ---
```

</details>

#### Group 2 — 3 configs, 27 instructions

Configurations in this group (exact Make flags):

- `O2-strict-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked`
- `O3-strict-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked`
- `Os-strict-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked`

```asm
auipc a2, 0x0
lw a3, 0x0(a2)
addi a3, a3, 0x1
li a4, 0x1f5
sw a3, 0x0(a2)
bgeu a3, a4, 0x12 <w2c_loadptr_do_load+0x12>
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
ret
addi sp, sp, -0x10
sw ra, 0xc(sp)
li a0, 0xa
auipc ra, 0x0
jalr ra <w2c_loadptr_do_load+0x48>
```

<details>
<summary>Build output (3 <code>make</code> invocations, stdout &amp; stderr)</summary>

```
$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-unchecked DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-unchecked
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-unchecked/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-unchecked/loadptr.wasm.c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-unchecked/loadptr.wasm
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=0 -DWASM_RT_DISABLE_MEMCHECK_GENERAL=1 -DWASM_RT_DISABLE_RANGE_CHECK=1 -O2 -Ibuild/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-unchecked \
    -c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-unchecked/loadptr.wasm.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-unchecked/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-unchecked DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-unchecked
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-unchecked/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-unchecked/loadptr.wasm.c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-unchecked/loadptr.wasm
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=0 -DWASM_RT_DISABLE_MEMCHECK_GENERAL=1 -DWASM_RT_DISABLE_RANGE_CHECK=1 -O3 -Ibuild/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-unchecked \
    -c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-unchecked/loadptr.wasm.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-unchecked/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-unchecked DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-unchecked
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-unchecked/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-unchecked/loadptr.wasm.c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-unchecked/loadptr.wasm
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=0 -DWASM_RT_DISABLE_MEMCHECK_GENERAL=1 -DWASM_RT_DISABLE_RANGE_CHECK=1 -Os -Ibuild/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-unchecked \
    -c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-unchecked/loadptr.wasm.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-unchecked/loadptr.wasm.o
--- stderr ---
```

</details>

#### Group 3 — 3 configs, 32 instructions

Configurations in this group (exact Make flags):

- `O2-unaligned-branches` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches`
- `O3-unaligned-branches` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches`
- `Os-unaligned-branches` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches`

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

<details>
<summary>Build output (3 <code>make</code> invocations, stdout &amp; stderr)</summary>

```
$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-branches DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-branches
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-branches/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-branches/loadptr.wasm.c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-branches/loadptr.wasm
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -mno-strict-align -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=1 -O2 -Ibuild/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-branches \
    -c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-branches/loadptr.wasm.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-branches/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-branches DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-branches
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-branches/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-branches/loadptr.wasm.c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-branches/loadptr.wasm
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -mno-strict-align -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=1 -O3 -Ibuild/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-branches \
    -c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-branches/loadptr.wasm.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-branches/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-branches DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-branches
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-branches/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-branches/loadptr.wasm.c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-branches/loadptr.wasm
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -mno-strict-align -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=1 -Os -Ibuild/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-branches \
    -c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-branches/loadptr.wasm.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-branches/loadptr.wasm.o
--- stderr ---
```

</details>

#### Group 4 — 3 configs, 18 instructions

Configurations in this group (exact Make flags):

- `O2-unaligned-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked`
- `O3-unaligned-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked`
- `Os-unaligned-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked`

```asm
auipc a2, 0x0
lw a3, 0x0(a2)
addi a3, a3, 0x1
li a4, 0x1f5
sw a3, 0x0(a2)
bgeu a3, a4, 0x12 <w2c_loadptr_do_load+0x12>
lw a0, 0x30(a0)
add a0, a0, a1
lw a0, 0x0(a0)
lw a1, 0x0(a2)
addi a1, a1, -0x1
sw a1, 0x0(a2)
ret
addi sp, sp, -0x10
sw ra, 0xc(sp)
li a0, 0xa
auipc ra, 0x0
jalr ra <w2c_loadptr_do_load+0x2e>
```

<details>
<summary>Build output (3 <code>make</code> invocations, stdout &amp; stderr)</summary>

```
$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-unchecked DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-unchecked
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-unchecked/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-unchecked/loadptr.wasm.c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-unchecked/loadptr.wasm
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -mno-strict-align -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=0 -DWASM_RT_DISABLE_MEMCHECK_GENERAL=1 -DWASM_RT_DISABLE_RANGE_CHECK=1 -O2 -Ibuild/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-unchecked \
    -c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-unchecked/loadptr.wasm.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-unchecked/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-unchecked DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-unchecked
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-unchecked/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-unchecked/loadptr.wasm.c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-unchecked/loadptr.wasm
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -mno-strict-align -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=0 -DWASM_RT_DISABLE_MEMCHECK_GENERAL=1 -DWASM_RT_DISABLE_RANGE_CHECK=1 -O3 -Ibuild/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-unchecked \
    -c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-unchecked/loadptr.wasm.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-unchecked/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-unchecked DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-unchecked
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-unchecked/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-unchecked/loadptr.wasm.c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-unchecked/loadptr.wasm
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -mno-strict-align -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=0 -DWASM_RT_DISABLE_MEMCHECK_GENERAL=1 -DWASM_RT_DISABLE_RANGE_CHECK=1 -Os -Ibuild/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-unchecked \
    -c build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-unchecked/loadptr.wasm.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-unchecked/loadptr.wasm.o
--- stderr ---
```

</details>

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

<details>
<summary>Build output (12 <code>make</code> invocations, stdout &amp; stderr)</summary>

```
$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-branches DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-branches
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -O2 -c analysis/cases/loadptr.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-branches/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-unchecked DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-unchecked
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -O2 -c analysis/cases/loadptr.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-strict-unchecked/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-branches DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-branches
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -mno-strict-align -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -O2 -c analysis/cases/loadptr.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-branches/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-unchecked DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-unchecked
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -mno-strict-align -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -O2 -c analysis/cases/loadptr.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O2-unaligned-unchecked/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-branches DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-branches
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -O3 -c analysis/cases/loadptr.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-branches/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-unchecked DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-unchecked
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -O3 -c analysis/cases/loadptr.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-strict-unchecked/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-branches DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-branches
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -mno-strict-align -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -O3 -c analysis/cases/loadptr.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-branches/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-unchecked DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-unchecked
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -mno-strict-align -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -O3 -c analysis/cases/loadptr.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/O3-unaligned-unchecked/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-branches DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-branches
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -Os -c analysis/cases/loadptr.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-branches/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-unchecked DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-unchecked
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -Os -c analysis/cases/loadptr.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-strict-unchecked/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-branches DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-branches
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -mno-strict-align -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -Os -c analysis/cases/loadptr.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-branches/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-unchecked DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-unchecked
clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/8ladf4anvpv05m40mhiibzvv2rm50k2h-wabt-1.0.41/include -mno-strict-align -I/nix/store/hg0mc7n5c83ycv3h2ihp06lng2vwmnxr-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include -Os -c analysis/cases/loadptr.c -o build/analysis/riscv32-none-elf_clang21.1.8_rv32imafdc-ilp32d-medany_libgcc/loadptr/Os-unaligned-unchecked/loadptr.native.o
--- stderr ---
```

</details>
