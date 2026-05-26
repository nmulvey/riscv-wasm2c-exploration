#!/usr/bin/env bash
# Optimization ablation study for the 05_box test (both entrypoints).
#
# For each (config, target) pair: rebuild with `make BENCH=1 <flags>`, run the
# ELF, and report the cycle/instret counts printed by BENCH_END around the
# keygen call.
#
# Platform is chosen with PLATFORM (default: qemu):
#   PLATFORM=qemu       Build for RISC-V, run under qemu-system-riscv32 (virt).
#                       Run from inside `nix develop` (the RISC-V default shell).
#   PLATFORM=nrf52840   Build for ARM Cortex-M4F, flash + run on a real
#                       nRF52840-DK via scripts/run-nrf52840.sh. Run from inside
#                       `nix develop .#arm-cortex-m4-gcc`.
#
# NOTE on which number to read: QEMU implements neither rdcycle (RV) nor DWT
# CYCCNT (ARM), so under PLATFORM=qemu compare `instret`. On real nRF52840
# hardware `cycles` is a true 64 MHz core-cycle count (and `instret` is 0 —
# Cortex-M has no retired-instruction counter).
#
# Edit CONFIGS/TARGETS below to taste.

set -euo pipefail
cd "$(dirname "$0")/.."

PLATFORM="${PLATFORM:-qemu}"
# Isolated build dir for the nRF52840 ablation so it never clobbers a normal
# build_nrf52840/ tree. Wiped before each config to force a rebuild with the
# new flags (the Makefile's `clean` only removes build/, not build_nrf52840*/).
NRF_BUILD="${NRF_BUILD:-build_nrf52840_ablation}"

case "$PLATFORM" in
    qemu)
        command -v qemu-system-riscv32 >/dev/null || {
            echo "qemu-system-riscv32 not on PATH — run inside 'nix develop'." >&2
            exit 1
        }
        ;;
    nrf52840)
        { command -v openocd >/dev/null && command -v arm-none-eabi-gcc >/dev/null; } || {
            echo "openocd / arm-none-eabi-gcc not on PATH — run inside 'nix develop .#arm-cortex-m4-gcc'." >&2
            exit 1
        }
        ;;
    *)
        echo "Unknown PLATFORM='$PLATFORM' (valid: qemu, nrf52840)." >&2
        exit 1
        ;;
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
    local label="$1" flags="$2" target="$3" out
    if [ "$PLATFORM" = qemu ]; then
        make clean >/dev/null
        if ! make -j"$(nproc)" BENCH=1 $flags "build/05_box/$target" \
                >"$BUILD_LOG" 2>&1; then
            printf '  %-20s %-15s BUILD FAILED (see %s)\n' \
                "$label" "$target" "$BUILD_LOG"
            return
        fi
        out=$(timeout 60 qemu-system-riscv32 \
            -machine virt -bios none -nographic -semihosting \
            -kernel "build/05_box/$target" </dev/null 2>&1 | grep '\[bench' || true)
    else
        # nRF52840: wipe the isolated build dir so objects rebuild with the new
        # flags, build the ARM ELF, then flash + run it on hardware. The ELF
        # lands at $NRF_BUILD/05_box/$target; run it directly (not via the
        # phony run-nrf52840-* target) to avoid a redundant recursive rebuild.
        rm -rf "$NRF_BUILD"
        if ! make -j"$(nproc)" BENCH=1 NRF52840_BUILD="$NRF_BUILD" $flags \
                "build-nrf52840-$target" >"$BUILD_LOG" 2>&1; then
            printf '  %-20s %-15s BUILD FAILED (see %s)\n' \
                "$label" "$target" "$BUILD_LOG"
            return
        fi
        out=$(./scripts/run-nrf52840.sh "$NRF_BUILD/05_box/$target" \
            2>>"$BUILD_LOG" | grep '\[bench' || true)
    fi
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
