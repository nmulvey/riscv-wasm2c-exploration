#!/usr/bin/env bash
# Optimization ablation study for the 05_box test (both entrypoints).
#
# For each (config, target) pair: rebuild with `make clean && make BENCH=1
# <flags>`, run the ELF under QEMU, and report the cycle/instret counts
# printed by BENCH_END around the keygen call.
#
# Works on either ARCH_FAMILY (riscv32 / arm) by delegating the run to the
# Makefile's `qemu-<elf>` / `renode-<elf>` target instead of calling
# qemu-system-* directly — the Makefile already knows which binary, machine,
# and flags to use for the current arch.
#
# RUNNER selection (override with `RUNNER=qemu` or `RUNNER=renode`):
#   riscv32 → qemu   (rdcycle ≈ instret under qemu's `virt`; fine for
#                     ablation)
#   arm     → renode (qemu's mps2-an386 doesn't tick DWT CYCCNT, so cycles=
#                     would always read 0; Renode's DWT does tick)
# instret is always 0 on Cortex-M regardless of runner — Cortex-M has no
# architectural retired-instructions counter.
#
# Run from inside `nix develop`. Edit CONFIGS/TARGETS below to taste.

set -euo pipefail
cd "$(dirname "$0")/.."

[[ -n "${ARCH_FAMILY:-}" ]] || {
    echo "ARCH_FAMILY not set — run inside 'nix develop .#<arch>'." >&2
    exit 1
}

case "$ARCH_FAMILY" in
    riscv32) RUNNER="${RUNNER:-qemu}"   ;;
    arm)     RUNNER="${RUNNER:-renode}" ;;
    *) echo "unknown ARCH_FAMILY=$ARCH_FAMILY" >&2; exit 1 ;;
esac

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
    # Delegate the actual run to the Makefile's qemu-/renode-<elf> target so
    # the right emulator+machine+flags are dispatched per arch family.
    local out
    out=$(timeout 120 make BENCH=1 $flags "$RUNNER-$target" </dev/null 2>&1 \
            | grep '\[bench' || true)
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
