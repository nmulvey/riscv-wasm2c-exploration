#!/usr/bin/env bash
set -euo pipefail
SYSROOT=/nix/store/2v32jkf9azps60h3sf69iydx2y8c3shi-source/wasi-sdk-24.0-arm64-macos/share/wasi-sysroot
BUILTINS=/nix/store/2v32jkf9azps60h3sf69iydx2y8c3shi-source/wasi-sdk-24.0-arm64-macos/lib/clang/18/lib/wasi/libclang_rt.builtins-wasm32.a
RESDIR=/nix/store/2v32jkf9azps60h3sf69iydx2y8c3shi-source/wasi-sdk-24.0-arm64-macos/lib/clang/18
NEWLIB_INC=/nix/store/izvzbga16i04i2hgnw19d5210104yfhk-newlib-riscv32-none-elf-4.5.0.20241231/riscv32-none-elf/include
WABT_INC=/nix/store/3hkzl47pbwd08cpcdjy0cd50y5r2528y-wabt-1.0.41/include
WORK=$(mktemp -d); echo "workdir: $WORK"

cat > "$WORK/probe_used.c" <<'EOF'
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

cat > "$WORK/probe_unused.c" <<'EOF'
#include <stdio.h>
volatile int iv = 42;
int probe_entry(void) { return iv * 2; }
EOF

build_wasi () {
    clang --target=wasm32-wasi --sysroot="$SYSROOT" -O3 -resource-dir "$RESDIR" \
          -Wl,--no-entry -Wl,--export=probe_entry -Wl,--allow-undefined \
          -Wl,--gc-sections -mexec-model=reactor "$1" "$BUILTINS" -o "$2"
}

echo ">>> A: wasi-libc, printf USED"
build_wasi "$WORK/probe_used.c" "$WORK/A.wasm"
wasm2c -n probe -o "$WORK/A.wasm.c" "$WORK/A.wasm"
echo ">>> C: wasi-libc, printf UNUSED"
build_wasi "$WORK/probe_unused.c" "$WORK/C.wasm"
wasm2c -n probe -o "$WORK/C.wasm.c" "$WORK/C.wasm"

RVFLAGS="-march=rv32imafdc -mabi=ilp32d -mcmodel=medany --target=riscv32-none-elf \
         -O2 -ffunction-sections -fdata-sections -mno-strict-align \
         -Wno-unused-variable -Wno-unused-function -Wno-unused-value -Wno-unused-parameter \
         -I$WABT_INC -I$NEWLIB_INC"
clang $RVFLAGS -c "$WORK/A.wasm.c" -o "$WORK/A.wasm.o"
clang $RVFLAGS -c "$WORK/C.wasm.c" -o "$WORK/C.wasm.o"

echo; echo ">>> .text: printf used vs. printf available-but-unused"
llvm-size "$WORK/A.wasm.o" "$WORK/C.wasm.o"
echo
python3 - "$WORK/A.wasm.o" "$WORK/C.wasm.o" <<'PY'
import subprocess, sys
def text(o): return int(subprocess.check_output(["llvm-size", o]).decode().splitlines()[1].split()[0])
a, c = text(sys.argv[1]), text(sys.argv[2])
print(f"printf used:             {a:>8} B .text")
print(f"printf available/unused: {c:>8} B .text")
print(f"stripped when unused:    {a-c:>8} B")
print()
print("=> reachability-driven" if c < a*0.3 else "=> persists even when unused")
PY
echo; echo "workdir: $WORK"
