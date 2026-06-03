# wasm2c sandboxing — disassembly analysis

**Toolchain**

- target: `arm-none-eabi`
- compiler: `gcc 15.2.1`
- ABI flags: `-mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16`
- rtlib: `libgcc`
- id: `arm-none-eabi_gcc15.2.1_cortex-m4-hard-thumb-fpv4-sp-d16_libgcc`
- _resolved from: env vars where present, compiler query as fallback_

**Canonical pipeline flags** (from the Makefile)

- `WASM_CFLAGS` = `--target=wasm32 -O3 -nostdlib -fuse-ld=lld -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all`
- `CFLAGS` = `-mcpu=cortex-m4 -mfloat-abi=hard -mthumb -mfpu=fpv4-sp-d16 -O2 -g -ffunction-sections -fdata-sections -Wall -Wextra -Werror -Isrc -DWASM_RT_THREAD_LOCAL= -MMD -MP -I/nix/store/arh6aqqgd8s6zhgha7ngs3rdwjd2gl7m-wabt-1.0.41/include`

---
## `loadptr`

- **Sandboxed focus symbol:** `w2c_loadptr_do_load` (C → wasm → wasm2c → native)
- **Native baseline symbol:** `do_load` (C → native, no WASM)
- **Configurations swept:** 12

### Sandboxed (wasm2c) disassembly

2 distinct disassembly groups.

#### Group 1 — 8 configs, 25 instructions

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
ldr r2, [pc, #64] @ (44 <w2c_loadptr_do_load+0x44>)
ldr.w ip, [r2]
add.w r3, ip, #1
cmp.w r3, #500 @ 0x1f4
push {r4, lr}
str r3, [r2, #0]
bhi.n 3c <w2c_loadptr_do_load+0x3c>
ldr r4, [r0, #80] @ 0x50
adds.w lr, r1, #4
mov.w r3, #0
adc.w r3, r3, #0
cmp r4, lr
ldr r4, [r0, #84] @ 0x54
sbcs.w r3, r4, r3
bcc.n 36 <w2c_loadptr_do_load+0x36>
ldr r3, [r0, #48] @ 0x30
ldr r0, [r3, r1]
str.w ip, [r2]
pop {r4, pc}
movs r0, #1
bl 0 <wasm_rt_trap>
movs r0, #10
bl 0 <wasm_rt_trap>
nop
.word 0x00000000
```

#### Group 2 — 4 configs, 24 instructions

Configurations in this group (exact Make flags):

- `Os-strict-branches` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=branches`
- `Os-strict-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=0 WASM_BOUNDS_CHECKS=unchecked`
- `Os-unaligned-branches` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=branches`
- `Os-unaligned-unchecked` — `DEBUG=0 EXTRA_CFLAGS=-Os NO_STRICT_ALIGN=1 WASM_BOUNDS_CHECKS=unchecked`

```asm
push {r3, r4, r5, r6, r7, lr}
ldr r3, [pc, #48] @ (34 <w2c_loadptr_do_load+0x34>)
ldr r2, [r3, #0]
adds r4, r2, #1
cmp.w r4, #500 @ 0x1f4
str r4, [r3, #0]
bls.n 16 <w2c_loadptr_do_load+0x16>
movs r0, #10
bl 0 <wasm_rt_trap>
ldrd r7, r4, [r0, #80] @ 0x50
adds r6, r1, #4
ite cs
movcs r5, #1
movcc r5, #0
cmp r7, r6
sbcs r4, r5
bcs.n 2c <w2c_loadptr_do_load+0x2c>
movs r0, #1
b.n 12 <w2c_loadptr_do_load+0x12>
ldr r0, [r0, #48] @ 0x30
ldr r0, [r0, r1]
str r2, [r3, #0]
pop {r3, r4, r5, r6, r7, pc}
.word 0x00000000
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
ldr r0, [r0, #0]
bx lr
```
