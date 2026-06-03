# wasm2c sandboxing — disassembly analysis

**Toolchain**

- target: `arm-none-eabi`
- compiler: `clang 21.1.8`
- ABI flags: `-mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16`
- rtlib: `libgcc`
- id: `arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc`
- _resolved from: env vars where present, compiler query as fallback_

**Canonical pipeline flags** (from the Makefile)

- `WASM_CFLAGS` = `--target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all`
- `CFLAGS` = `-mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -g -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include`

---
## `loadptr`

- **Sandboxed focus symbol:** `w2c_loadptr_do_load` (C → wasm → wasm2c → native)
- **Native baseline symbol:** `do_load` (C → native, no WASM)
- **Configurations swept:** 12

### Sandboxed (wasm2c) disassembly

3 distinct disassembly groups.

#### Group 1 — 6 configs, 16 instructions

Configurations in this group (exact Make flags):

- `O2-strict-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked`
- `O2-unaligned-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked`
- `O3-strict-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked`
- `O3-unaligned-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked`
- `Os-strict-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked`
- `Os-unaligned-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked`

```asm
movw r2, #0x0
movt r2, #0x0
ldr r3, [r2]
adds r3, #0x1
cmp.w r3, #0x1f4
str r3, [r2]
bhi 0x20 <w2c_loadptr_do_load+0x20> @ imm = #0xa
ldr r0, [r0, #0x30]
ldr r0, [r0, r1]
ldr r1, [r2]
subs r1, #0x1
str r1, [r2]
bx lr
push {r7, lr}
movs r0, #0xa
bl 0x24 <w2c_loadptr_do_load+0x24> @ imm = #-0x4
```

<details>
<summary>Build output (6 <code>make</code> invocations, stdout &amp; stderr)</summary>

```
$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-unchecked DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-unchecked
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-unchecked/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-unchecked/loadptr.wasm.c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-unchecked/loadptr.wasm
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=0 -DWASM_RT_DISABLE_MEMCHECK_GENERAL=1 -O2 -Ibuild/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-unchecked \
    -c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-unchecked/loadptr.wasm.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-unchecked/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-unchecked DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-unchecked
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-unchecked/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-unchecked/loadptr.wasm.c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-unchecked/loadptr.wasm
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -munaligned-access -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=0 -DWASM_RT_DISABLE_MEMCHECK_GENERAL=1 -O2 -Ibuild/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-unchecked \
    -c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-unchecked/loadptr.wasm.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-unchecked/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-unchecked DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-unchecked
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-unchecked/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-unchecked/loadptr.wasm.c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-unchecked/loadptr.wasm
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=0 -DWASM_RT_DISABLE_MEMCHECK_GENERAL=1 -O3 -Ibuild/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-unchecked \
    -c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-unchecked/loadptr.wasm.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-unchecked/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-unchecked DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-unchecked
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-unchecked/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-unchecked/loadptr.wasm.c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-unchecked/loadptr.wasm
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -munaligned-access -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=0 -DWASM_RT_DISABLE_MEMCHECK_GENERAL=1 -O3 -Ibuild/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-unchecked \
    -c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-unchecked/loadptr.wasm.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-unchecked/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-unchecked DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-unchecked
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-unchecked/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-unchecked/loadptr.wasm.c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-unchecked/loadptr.wasm
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=0 -DWASM_RT_DISABLE_MEMCHECK_GENERAL=1 -Os -Ibuild/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-unchecked \
    -c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-unchecked/loadptr.wasm.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-unchecked/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-unchecked DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-unchecked
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-unchecked/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-unchecked/loadptr.wasm.c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-unchecked/loadptr.wasm
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -munaligned-access -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=0 -DWASM_RT_DISABLE_MEMCHECK_GENERAL=1 -Os -Ibuild/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-unchecked \
    -c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-unchecked/loadptr.wasm.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-unchecked/loadptr.wasm.o
--- stderr ---
```

</details>

#### Group 2 — 4 configs, 25 instructions

Configurations in this group (exact Make flags):

- `O2-strict-branches` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches`
- `O2-unaligned-branches` — `DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches`
- `Os-strict-branches` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches`
- `Os-unaligned-branches` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches`

```asm
push {r4, r5, r7, lr}
movw lr, #0x0
movt lr, #0x0
ldr.w r3, [lr]
adds r3, #0x1
cmp.w r3, #0x1f4
str.w r3, [lr]
bhi 0x46 <w2c_loadptr_do_load+0x46> @ imm = #0x2a
ldrd r2, r4, [r0, #80]
adds r5, r1, #0x4
mov.w r12, #0x0
adc r3, r12, #0x0
subs r2, r2, r5
sbcs.w r2, r4, r3
blo 0x40 <w2c_loadptr_do_load+0x40> @ imm = #0xe
ldr r0, [r0, #0x30]
ldr r0, [r0, r1]
ldr.w r1, [lr]
subs r1, #0x1
str.w r1, [lr]
pop {r4, r5, r7, pc}
movs r0, #0x1
bl 0x42 <w2c_loadptr_do_load+0x42> @ imm = #-0x4
movs r0, #0xa
bl 0x48 <w2c_loadptr_do_load+0x48> @ imm = #-0x4
```

<details>
<summary>Build output (4 <code>make</code> invocations, stdout &amp; stderr)</summary>

```
$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-branches DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-branches
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-branches/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-branches/loadptr.wasm.c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-branches/loadptr.wasm
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=1 -O2 -Ibuild/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-branches \
    -c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-branches/loadptr.wasm.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-branches/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-branches DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-branches
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-branches/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-branches/loadptr.wasm.c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-branches/loadptr.wasm
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -munaligned-access -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=1 -O2 -Ibuild/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-branches \
    -c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-branches/loadptr.wasm.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-branches/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-branches DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-branches
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-branches/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-branches/loadptr.wasm.c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-branches/loadptr.wasm
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=1 -Os -Ibuild/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-branches \
    -c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-branches/loadptr.wasm.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-branches/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-branches DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-branches
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-branches/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-branches/loadptr.wasm.c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-branches/loadptr.wasm
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -munaligned-access -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=1 -Os -Ibuild/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-branches \
    -c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-branches/loadptr.wasm.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-branches/loadptr.wasm.o
--- stderr ---
```

</details>

#### Group 3 — 2 configs, 26 instructions

Configurations in this group (exact Make flags):

- `O3-strict-branches` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches`
- `O3-unaligned-branches` — `DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches`

```asm
push {r4, r5, r7, lr}
movw lr, #0x0
movt lr, #0x0
ldr.w r3, [lr]
adds r3, #0x1
cmp.w r3, #0x1f4
str.w r3, [lr]
bhi 0x48 <w2c_loadptr_do_load+0x48> @ imm = #0x2c
ldrd r2, r4, [r0, #80]
adds r5, r1, #0x4
mov.w r12, #0x0
adc r3, r12, #0x0
subs r2, r2, r5
sbcs.w r2, r4, r3
blo 0x40 <w2c_loadptr_do_load+0x40> @ imm = #0xe
ldr r0, [r0, #0x30]
ldr r0, [r0, r1]
ldr.w r1, [lr]
subs r1, #0x1
str.w r1, [lr]
pop {r4, r5, r7, pc}
movs r0, #0x1
bl 0x42 <w2c_loadptr_do_load+0x42> @ imm = #-0x4
nop
movs r0, #0xa
bl 0x4a <w2c_loadptr_do_load+0x4a> @ imm = #-0x4
```

<details>
<summary>Build output (2 <code>make</code> invocations, stdout &amp; stderr)</summary>

```
$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-branches DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-branches
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-branches/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-branches/loadptr.wasm.c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-branches/loadptr.wasm
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=1 -O3 -Ibuild/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-branches \
    -c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-branches/loadptr.wasm.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-branches/loadptr.wasm.o
--- stderr ---


$ make analysis-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-branches DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-branches
clang --target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all  -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-branches/loadptr.wasm analysis/cases/loadptr.c
wasm2c -n loadptr -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-branches/loadptr.wasm.c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-branches/loadptr.wasm
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -munaligned-access -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=1 -O3 -Ibuild/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-branches \
    -c build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-branches/loadptr.wasm.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-branches/loadptr.wasm.o
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
ldr r0, [r0]
bx lr
```

<details>
<summary>Build output (12 <code>make</code> invocations, stdout &amp; stderr)</summary>

```
$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-branches DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-branches
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -O2 -c analysis/cases/loadptr.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-branches/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-unchecked DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-unchecked
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -O2 -c analysis/cases/loadptr.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-strict-unchecked/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-branches DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-branches
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -munaligned-access -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -O2 -c analysis/cases/loadptr.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-branches/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-unchecked DEBUG=0 EXTRA_CFLAGS=-O2 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-unchecked
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -munaligned-access -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -O2 -c analysis/cases/loadptr.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O2-unaligned-unchecked/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-branches DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-branches
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -O3 -c analysis/cases/loadptr.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-branches/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-unchecked DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-unchecked
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -O3 -c analysis/cases/loadptr.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-strict-unchecked/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-branches DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-branches
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -munaligned-access -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -O3 -c analysis/cases/loadptr.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-branches/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-unchecked DEBUG=0 EXTRA_CFLAGS=-O3 NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-unchecked
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -munaligned-access -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -O3 -c analysis/cases/loadptr.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/O3-unaligned-unchecked/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-branches DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-branches
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -Os -c analysis/cases/loadptr.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-branches/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-unchecked DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-unchecked
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -Os -c analysis/cases/loadptr.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-strict-unchecked/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-branches DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-branches
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -munaligned-access -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -Os -c analysis/cases/loadptr.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-branches/loadptr.native.o
--- stderr ---


$ make analysis-native-object CASE=loadptr ANALYSIS_OUT=build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-unchecked DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked
--- stdout ---
mkdir -p build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-unchecked
clang -mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 --target=thumbv7em-none-eabihf -O2 -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/lhlmj8629y0gqzxqgw82vh51vpy7ws3j-wabt-1.0.41/include -munaligned-access -I/nix/store/mzv3p867fyhi31lhj5flazyfbq79jw41-gcc-arm-embedded-15.2.rel1/arm-none-eabi/include -Os -c analysis/cases/loadptr.c -o build/analysis/arm-none-eabi_clang21.1.8_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc/loadptr/Os-unaligned-unchecked/loadptr.native.o
--- stderr ---
```

</details>
