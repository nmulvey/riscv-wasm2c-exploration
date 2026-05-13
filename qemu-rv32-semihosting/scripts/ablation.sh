#!/usr/bin/env bash
# Optimization ablation study for the 05_box test (both entrypoints).
#
# For each (config, target) pair: rebuild with `make clean && make BENCH=1
# <flags>`, run the ELF under QEMU, and report the cycle/instret counts
# printed by BENCH_END around the keygen call.
#
# Run from inside `nix develop`. Edit CONFIGS/TARGETS below to taste.

set -euo pipefail
cd "$(dirname "$0")/.."

command -v qemu-system-riscv32 >/dev/null || {
    echo "qemu-system-riscv32 not on PATH — run inside 'nix develop'." >&2
    exit 1
}

# "label : make-flags"
CONFIGS=(
    "baseline           : "
    "LTO                : LTO=1"
    "O3_WASM            : O3_WASM=1"
    "UNROLL_WASM        : UNROLL_WASM=1"
    "LTO + O3_WASM      : LTO=1 O3_WASM=1"
    "all                : LTO=1 O3_WASM=1 UNROLL_WASM=1"
)
TARGETS=( 05_box_native 05_box_wasm )

BUILD_LOG=$(mktemp)
trap 'rm -f "$BUILD_LOG"' EXIT

run() {
    local label="$1" flags="$2" target="$3"
    make clean >/dev/null
    if ! make -j"$(nproc)" BENCH=1 $flags "build/05_box/$target" \
            >"$BUILD_LOG" 2>&1; then
        printf '  %-20s %-15s BUILD FAILED (see %s)\n' \
            "$label" "$target" "$BUILD_LOG"
        return
    fi
    local out
    out=$(timeout 60 qemu-system-riscv32 \
        -machine virt -bios none -nographic -semihosting \
        -kernel "build/05_box/$target" </dev/null 2>&1 | grep '\[bench' || true)
    printf '  %-20s %-15s %s\n' "$label" "$target" "$out"
}

# trim leading/trailing spaces
trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; printf '%s' "${s%"${s##*[![:space:]]}"}"; }

printf '  %-20s %-15s %s\n' config target result
printf '  %-20s %-15s %s\n' ------ ------ ------
for tgt in "${TARGETS[@]}"; do
    for cfg in "${CONFIGS[@]}"; do
        label=$(trim "${cfg%%:*}")
        flags=$(trim "${cfg#*:}")
        run "$label" "$flags" "$tgt"
    done
    echo
done
