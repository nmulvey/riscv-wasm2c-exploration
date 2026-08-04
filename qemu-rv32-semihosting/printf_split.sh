#!/usr/bin/env bash
# Why is the duplicated printf so huge? Split it into (a) raw duplication -- one
# extra copy of printf you didn't need -- and (b) the WASM tax on that copy
# (alignment + bounds + wasm2c codegen). Native newlib printf is the "one copy"
# baseline; the sandbox copy above that is the WASM overhead.
set -euo pipefail

SYSROOT=/nix/store/2v32jkf9azps60h3sf69iydx2y8c3shi-source/wasi-sdk-24.0-arm64-macos/share/wasi-sysroot
BUILTINS=/nix/store/2v32jkf9azps60h3sf69iydx2y8c3shi-source/wasi-sdk-24.0-arm64-macos/lib/clang/18/lib/wasi/libclang_rt.builtins-wasm32.a
RESDIR=/nix/store/2v32jkf9azps60h3sf69iydx2y8c3shi-source/wasi-sdk-24.0-arm64-macos/lib/clang/18
NEWLIB=/nix/store/izvzbga16i04i2hgnw19d5210104yfhk-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf
WABT_INC=/nix/store/3hkzl47pbwd08cpcdjy0cd50y5r2528y-wabt-1.0.41/include
WORK=$(mktemp -d); echo "workdir: $WORK"

# ---------- native newlib printf: the "one copy" baseline ----------
# Sum printf/vfprintf/dtoa (float conversion) symbols straight out of libc.a.
# No linking needed -- this is the irreducible size of one printf on the target.
echo ">>> native newlib printf-family symbols"
NATIVE=$(llvm-nm --print-size --size-sort "$NEWLIB/lib/libc.a" 2>/dev/null \
  | grep -iE "printf|vfprintf|dtoa|mprec|mbtowc|wctomb" \
  | awk '{s+=strtonum("0x"$2)} END {print s+0}')
echo "   native printf-family .text: $NATIVE B"

# ---------- sandbox printf through WASM, three ablation levels ----------
cat > "$WORK/probe.c" <<'EOF'
#include <stdio.h>
volatile double dv = 3.14159265358979;
volatile int iv = 42;
char buf[256];
int probe_entry(void) {
    int n = snprintf(buf, sizeof buf, "d=%.6f i=%d\n", dv, iv);
    printf("%s", buf);
    return n;
}
EOF

echo ">>> building sandbox printf (wasi-libc -> wasm2c)"
clang --target=wasm32-wasi --sysroot="$SYSROOT" -O3 -resource-dir "$RESDIR" \
      -Wl,--no-entry -Wl,--export=probe_entry -Wl,--allow-undefined \
      -Wl,--gc-sections -mexec-model=reactor \
      "$WORK/probe.c" "$BUILTINS" -o "$WORK/sb.wasm"
wasm2c -n probe -o "$WORK/sb.wasm.c" "$WORK/sb.wasm"

rv () {  # $1 extra flags  $2 out.o
    clang -march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf \
          -O2 -ffunction-sections -fdata-sections \
          -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter \
          -I"$WABT_INC" -I"$NEWLIB/include" $1 -c "$WORK/sb.wasm.c" -o "$2"
}
echo ">>> sandbox printf, three ablation levels"
rv "-mstrict-align -DWASM_RT_MEMCHECK_BOUNDS_CHECK=1"    "$WORK/sb_full.o"
rv "-mno-strict-align -DWASM_RT_MEMCHECK_BOUNDS_CHECK=1" "$WORK/sb_align.o"
rv "-mno-strict-align -DWASM_RT_MEMCHECK_GUARD_PAGES=0 -DWASM_RT_MEMCHECK_BOUNDS_CHECK=0 -DWASM_RT_DISABLE_MEMCHECK_GENERAL=1 -DWASM_RT_DISABLE_RANGE_CHECK=1" "$WORK/sb_none.o"

echo
echo ">>> .text sizes"
llvm-size "$WORK/sb_full.o" "$WORK/sb_align.o" "$WORK/sb_none.o"

echo
python3 - "$NATIVE" "$WORK/sb_full.o" "$WORK/sb_align.o" "$WORK/sb_none.o" <<'PY'
import subprocess, sys
def t(o): return int(subprocess.check_output(["llvm-size", o]).decode().splitlines()[1].split()[0])
nat = int(sys.argv[1])
full, align, none = map(t, sys.argv[2:5])
print(f"native printf (one copy):        {nat:>8} B")
print(f"sandbox printf, full overhead:   {full:>8} B")
print(f"sandbox printf, -mno-strict-align:{align:>8} B")
print(f"sandbox printf, +bounds off:     {none:>8} B")
print()
print(f"  alignment tax on the copy:     {full-align:>8} B")
print(f"  bounds-check tax on the copy:  {align-none:>8} B")
print(f"  wasm2c structural tax:         {none-nat:>8} B  (sandbox-stripped minus native)")
print(f"  raw duplication:               {nat:>8} B  (the 'you have it twice' cost)")
print()
tax = full - nat
print(f"  => of the {full} B sandbox printf, {nat} B is duplication and {tax} B is WASM tax")
PY
echo; echo "workdir: $WORK"
