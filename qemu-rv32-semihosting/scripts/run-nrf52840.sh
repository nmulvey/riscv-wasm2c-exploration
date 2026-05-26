#!/usr/bin/env bash
#
# Flash an ARM Cortex-M4F ELF onto an nRF52840-DK over its on-board SEGGER
# J-Link, run it, and stream ARM semihosting console output to stdout.
#
# This is the hardware analogue of the `qemu-<elf>` Makefile targets: where
# QEMU's `mps2-an386` machine intercepts the BKPT 0xAB semihosting calls, here
# OpenOCD does the same over SWD. No firmware changes are needed — the same
# librdimon `initialise_monitor_handles` / printf / exit path drives both.
#
# How it works (OpenOCD standalone, no GDB):
#   init; halt; program <elf>; reset halt; arm semihosting enable; resume
# OpenOCD services SYS_WRITE calls during polling (and resumes the core), and
# leaves the core halted when the program makes the SYS_EXIT semihosting call.
# `wait_halt` therefore returns exactly when the program has exited.
#
# Output routing: OpenOCD's own log goes to stderr (and is only echoed on
# failure); the target's semihosting fd-1 writes go to this script's stdout,
# so the output diffs cleanly against tests/<t>/expected.txt — exactly like
# the QEMU `nix flake check` path.
#
# Usage:
#   scripts/run-nrf52840.sh [--flash-only] <elf>
#
# Environment overrides:
#   OPENOCD             openocd binary               (default: openocd)
#   OPENOCD_INTERFACE   interface config             (default: interface/jlink.cfg)
#   OPENOCD_TARGET      target config                (default: target/nrf52.cfg)
#   OPENOCD_TRANSPORT   transport                    (default: swd)
#   NRF_TIMEOUT_MS      max run time before giving up (default: 60000)
#   NRF_RETRIES         OpenOCD attempts on failure   (default: 3)
set -euo pipefail

OPENOCD="${OPENOCD:-openocd}"
OPENOCD_INTERFACE="${OPENOCD_INTERFACE:-interface/jlink.cfg}"
OPENOCD_TARGET="${OPENOCD_TARGET:-target/nrf52.cfg}"
OPENOCD_TRANSPORT="${OPENOCD_TRANSPORT:-swd}"
NRF_TIMEOUT_MS="${NRF_TIMEOUT_MS:-60000}"
NRF_RETRIES="${NRF_RETRIES:-5}"

flash_only=0
elf=""
while [ $# -gt 0 ]; do
    case "$1" in
        --flash-only) flash_only=1; shift ;;
        -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
        -*) echo "run-nrf52840.sh: unknown option '$1'" >&2; exit 2 ;;
        *)  elf="$1"; shift ;;
    esac
done

if [ -z "$elf" ]; then
    echo "Usage: run-nrf52840.sh [--flash-only] <elf>" >&2
    exit 2
fi
if [ ! -f "$elf" ]; then
    echo "run-nrf52840.sh: ELF not found: $elf" >&2
    exit 2
fi
if ! command -v "$OPENOCD" >/dev/null 2>&1; then
    echo "run-nrf52840.sh: '$OPENOCD' not on PATH. Enter the dev shell (nix develop .#arm-cortex-m4-gcc) or install openocd." >&2
    exit 127
fi

# OpenOCD's TCL `program`/`load_image` want a forward-slash path; bash paths
# already are, but normalise relative paths to absolute so OpenOCD's cwd
# doesn't matter.
elf_abs="$(cd "$(dirname "$elf")" && pwd)/$(basename "$elf")"

# Adapter + transport + target wiring, shared by both modes. Using inline
# `adapter driver` keeps us robust across OpenOCD versions where the bundled
# interface/jlink.cfg is a thin wrapper around exactly this.
common_setup=(
    -c "adapter driver jlink"
    -c "transport select ${OPENOCD_TRANSPORT}"
    -f "${OPENOCD_TARGET}"
)

log="$(mktemp -t openocd-nrf52840.XXXXXX.log)"
out="$(mktemp -t openocd-nrf52840.XXXXXX.out)"
cleanup() { rm -f "$log" "$out"; }
trap cleanup EXIT

# Run OpenOCD, retrying transient failures. Back-to-back J-Link sessions can
# fail to attach when looping over the whole suite: the on-board J-Link caps
# concurrent connections ("Registration failed: maximum number of connections
# on the device reached") and only drops a stale one a few seconds after the
# previous OpenOCD exits. We back off progressively (1s, 2s, 3s, …) to let it
# clear. We capture the target's semihosting output to $out (not straight to
# our stdout) so a failed attempt's partial output is discarded rather than
# interleaved with the retry; only on success do we emit $out. OpenOCD's own
# log ($log) is shown on final failure.
run_openocd() {
    local attempt rc=0
    for attempt in $(seq 1 "$NRF_RETRIES"); do
        if "$OPENOCD" "${common_setup[@]}" "$@" >"$out" 2>"$log"; then
            cat "$out"
            return 0
        fi
        rc=$?
        if [ "$attempt" -lt "$NRF_RETRIES" ]; then
            echo "run-nrf52840.sh: OpenOCD attempt $attempt/$NRF_RETRIES failed (exit $rc); retrying in ${attempt}s..." >&2
            sleep "$attempt"
        fi
    done
    echo "run-nrf52840.sh: OpenOCD failed after $NRF_RETRIES attempts (exit $rc). Log:" >&2
    cat "$log" >&2
    return "$rc"
}

if [ "$flash_only" -eq 1 ]; then
    echo "run-nrf52840.sh: flashing $elf_abs ..." >&2
    run_openocd \
        -c "init" \
        -c "halt" \
        -c "program {${elf_abs}} verify reset" \
        -c "shutdown"
    echo "run-nrf52840.sh: flashed (and reset to run)." >&2
    exit 0
fi

run_openocd \
    -c "init" \
    -c "halt" \
    -c "program {${elf_abs}} verify" \
    -c "reset halt" \
    -c "arm semihosting enable" \
    -c "resume" \
    -c "wait_halt ${NRF_TIMEOUT_MS}" \
    -c "shutdown"
