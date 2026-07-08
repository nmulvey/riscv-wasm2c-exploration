#!/usr/bin/env bash
# How much does printf cost when it's duplicated inside the sandbox? Build the
# same probe twice: once with printf compiled in (wasi-libc), once with it left
# as a host import (-nostdlib). Difference in .text is the duplicated formatter.
#
# Run inside: nix develop '.#rv32imafdc-clang-libgcc' --command bash printf_probe.sh

set -euo pipefail

SYSROOT=/nix/store/2v32jkf9azps60h3sf69iydx2y8c3shi-source/wasi-sdk-24.0-arm64-macos/share/wasi-sysroot
BUILTINS=/nix/store/2v32jkf9azps60h3sf69iydx2y8c3shi-source/wasi-sdk-24.0-arm64-macos/lib/clang/18/lib/wasi/libclang_rt.builtins-wasm32.a
WORK=$(mktemp -d)
echo "workdir: $WORK"

cat > "$WORK/probe.c" <<'EOF'
#include <stdio.h>
volatile double dv = 3.14159265358979;
volatile int    iv = 42;
volatile unsigned uv = 0xDEADBEEF;
const char *sv = "sandbox";
char buf[256];
int probe_entry(void) {
    int n = snprintf(buf, sizeof buf,
                     "d=%.6f i=%d u=%08x s=%-10s pct=%3.1f%%\n",
                     dv, iv, uv, sv, dv * 10.0);
    printf("%s", buf);
    return n;
}
EOF

wasm2c_of() { wasm2c -n probe -o "$2" "$1"; }

echo ">>> Version A: printf compiled into the module (against wasi-libc)"
# -resource-dir /nix/store/2v32jkf9azps60h3sf69iydx2y8c3shi-source/wasi-sdk-24.0-arm64-macos/lib/clang/18 stops clang from auto-searching its own (missing) wasm builtins;
# we hand it the wasi-sdk's builtins .a directly as a positional arg instead.
clang --target=wasm32-wasi --sysroot="$SYSROOT" -O3 -resource-dir /nix/store/2v32jkf9azps60h3sf69iydx2y8c3shi-source/wasi-sdk-24.0-arm64-macos/lib/clang/18 \
      -Wl,--no-entry -Wl,--export=probe_entry -Wl,--allow-undefined -mexec-model=reactor \
      "$WORK/probe.c" "$BUILTINS" -o "$WORK/probe_A.wasm"
wasm2c_of "$WORK/probe_A.wasm" "$WORK/probe_A.wasm.c"

echo ">>> Version B: printf left as a host import (-nostdlib, stays undefined)"
clang --target=wasm32-wasi -O3 -nostdlib -fuse-ld=lld --sysroot /nix/store/2v32jkf9azps60h3sf69iydx2y8c3shi-source/wasi-sdk-24.0-arm64-macos/share/wasi-sysroot \
      -Wl,--no-entry -Wl,--allow-undefined -Wl,--export-all \
      "$WORK/probe.c" -o "$WORK/probe_B.wasm"
wasm2c_of "$WORK/probe_B.wasm" "$WORK/probe_B.wasm.c"

RVFLAGS="-march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf \
         -O2 -ffunction-sections -fdata-sections -mno-strict-align \
         -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter \
         -I/nix/store/3hkzl47pbwd08cpcdjy0cd50y5r2528y-wabt-1.0.41/include -I/nix/store/izvzbga16i04i2hgnw19d5210104yfhk-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include"

echo; echo "compiling A -> RV32 object"
clang $RVFLAGS -c "$WORK/probe_A.wasm.c" -o "$WORK/probe_A.wasm.o"
echo "compiling B -> RV32 object"
clang $RVFLAGS -c "$WORK/probe_B.wasm.c" -o "$WORK/probe_B.wasm.o"

echo
echo ">>> Results -- duplicated code shows up in .text of the wasm2c object"
llvm-size "$WORK/probe_A.wasm.o" "$WORK/probe_B.wasm.o"

echo
python3 - "$WORK/probe_A.wasm.o" "$WORK/probe_B.wasm.o" <<'PY'
import subprocess, sys
def text(o):
    return int(subprocess.check_output(["llvm-size", o]).decode().splitlines()[1].split()[0])
a, b = text(sys.argv[1]), text(sys.argv[2])
print(f"A (printf in sandbox):  {a:>8} B .text")
print(f"B (printf host import): {b:>8} B .text")
print(f"DUPLICATED printf cost: {a-b:>8} B  ({(a-b)/1024:.1f} KB)")
PY

echo
echo "workdir: $WORK"
