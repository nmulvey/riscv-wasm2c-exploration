#!/usr/bin/env bash
# Code size ablation for the 05_box test (both entrypoints).
#
# For each config: rebuild clean, parse `size -A` output for the loadable
# sections, and report per-section bytes for native + wasm plus the
# sandbox overhead (Δ = wasm − native) per section.
#
# Flash = .text + .rodata (incl. .init_array) + .data
# RAM   = .data + .bss (incl. the wasm-rt 64 KB guest heap)
#
# Run from inside `nix develop`. Edit CONFIGS below to taste.
#
# Known issue: `OS=1` and `OS_WASM=1` _without_ LTO fail to link against
# this flake's cross-toolchain. `-Os` outlines 64-bit shifts into libgcc
# helpers (__lshrdi3, __ashldi3) and the shipped libgcc.a has a hard-float
# ABI that doesn't match our soft-float build. LTO sidesteps the problem
# by re-deciding inlining at link time, so the LTO+OS combos work.

set -euo pipefail
cd "$(dirname "$0")/.."

command -v riscv32-none-elf-size >/dev/null || {
    echo "riscv32-none-elf-size not on PATH — run inside 'nix develop'." >&2
    exit 1
}

# "label : make-flags"
CONFIGS=(
    "baseline      : "
    "LTO           : LTO=1"
    "OS_WASM       : OS_WASM=1"
    "OS            : OS=1"
    "LTO + OS_WASM : LTO=1 OS_WASM=1"
    "LTO + OS      : LTO=1 OS=1"
)

LOG=$(mktemp)
trap 'rm -f "$LOG"' EXIT

trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    printf '%s' "${s%"${s##*[![:space:]]}"}"
}

# Sum loadable sections from `size -A`. Prints "text rodata data bss".
sections() {
    riscv32-none-elf-size -A "$1" | awk '
        $1==".text"       { text   += $2 }
        $1==".rodata"     { rodata += $2 }
        $1==".init_array" { rodata += $2 }
        $1==".data"       { data   += $2 }
        $1==".bss"        { bss    += $2 }
        END { printf "%d %d %d %d\n", text+0, rodata+0, data+0, bss+0 }
    '
}

row() {
    local label="$1" target="$2" text="$3" rodata="$4" data="$5" bss="$6"
    local flash=$((text + rodata + data))
    local ram=$((data + bss))
    printf '  %-14s %-11s %7d %7d %5d %7d %8d %8d\n' \
        "$label" "$target" "$text" "$rodata" "$data" "$bss" "$flash" "$ram"
}

delta_row() {
    local nt=$1 nr=$2 nd=$3 nb=$4 wt=$5 wr=$6 wd=$7 wb=$8
    local dt=$((wt - nt)) dr=$((wr - nr)) dd=$((wd - nd)) db=$((wb - nb))
    local df=$((dt + dr + dd)) dm=$((dd + db))
    printf '  %-14s %-11s %+7d %+7d %+5d %+7d %+8d %+8d\n' \
        "" "Δ sandbox" "$dt" "$dr" "$dd" "$db" "$df" "$dm"
}

run() {
    local label="$1" flags="$2"
    make clean >/dev/null
    if ! make -j"$(nproc)" $flags \
            build/05_box/05_box_native build/05_box/05_box_wasm \
            >"$LOG" 2>&1; then
        printf '  %-14s %-11s BUILD FAILED (see %s)\n\n' "$label" "" "$LOG"
        return
    fi
    read -r nt nr nd nb < <(sections build/05_box/05_box_native)
    read -r wt wr wd wb < <(sections build/05_box/05_box_wasm)
    row       "$label" native "$nt" "$nr" "$nd" "$nb"
    row       "$label" wasm   "$wt" "$wr" "$wd" "$wb"
    delta_row          "$nt" "$nr" "$nd" "$nb" "$wt" "$wr" "$wd" "$wb"
    echo
}

printf '  %-14s %-11s %7s %7s %5s %7s %8s %8s\n' \
    config target text rodata data bss flash ram
printf '  %-14s %-11s %7s %7s %5s %7s %8s %8s\n' \
    ------ ------ ---- ------ ---- --- ----- ---

for cfg in "${CONFIGS[@]}"; do
    run "$(trim "${cfg%%:*}")" "$(trim "${cfg#*:}")"
done
