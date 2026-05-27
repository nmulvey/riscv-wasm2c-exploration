#!/usr/bin/env bash
#
# Flash an ARM Cortex-M4F ELF onto an nRF52840-DK over its on-board SEGGER
# J-Link, run it, and stream ARM semihosting console output to stdout.
#
# Two backends drive the same on-board probe:
#   * jlink   — SEGGER's own JLinkGDBServer + a cross-gdb. Preferred when
#               available; talks to the J-Link natively.
#   * openocd — OpenOCD over SWD (the original path). Used as a fallback.
# The selection is automatic by default; override with RUN_NRF52840_BACKEND.
#
# This is the hardware analogue of the `qemu-<elf>` Makefile targets: where
# QEMU's `mps2-an386` machine intercepts the BKPT 0xAB semihosting calls,
# the on-board J-Link does the same over SWD. No firmware changes are
# needed — the same librdimon `initialise_monitor_handles` / printf / exit
# path drives both.
#
# How it works (J-Link, no GDB session visible to the user):
#   JLinkGDBServer -singlerun -nogui -silent (background) listens on $JLINK_PORT.
#   arm-none-eabi-gdb -batch then: target remote; monitor semihosting enable;
#   monitor semihosting IOClient 2 (route SYS_WRITE through GDB O-packets);
#   load; monitor reset; continue; quit. When the program issues SYS_EXIT
#   the core halts, `continue` returns, GDB quits, and `-singlerun` makes
#   JLinkGDBServer exit too.
#
# How it works (OpenOCD standalone, no GDB):
#   init; halt; program <elf>; reset halt; arm semihosting enable; resume
#   OpenOCD services SYS_WRITE calls during polling (and resumes the core),
#   and leaves the core halted when the program makes the SYS_EXIT
#   semihosting call. `wait_halt` therefore returns exactly when the
#   program has exited.
#
# Output routing (both backends): the backend's own log goes to stderr (and
# is only echoed on failure); the target's semihosting fd-1 writes go to
# this script's stdout, so the output diffs cleanly against
# tests/<t>/expected.txt — exactly like the QEMU `nix flake check` path.
# For the J-Link backend specifically, `set logging redirect on` keeps GDB's
# CLI chatter in the logfile while inferior O-packet output stays on stdout.
#
# Usage:
#   scripts/run-nrf52840.sh [--flash-only] <elf>
#
# Common environment overrides:
#   RUN_NRF52840_BACKEND  jlink|openocd|auto             (default: auto)
#   NRF_TIMEOUT_MS        max run time before giving up  (default: 60000)
#   NRF_RETRIES           backend attempts on failure    (default: 5)
#
# J-Link backend overrides:
#   JLINK_GDB_SERVER      JLinkGDBServer binary    (default: JLinkGDBServer)
#   JLINK_DEVICE          device id                (default: nRF52840_xxAA)
#   JLINK_SPEED           SWD speed (kHz)          (default: 4000)
#   JLINK_PORT            local GDB TCP port       (default: 2331)
#   GDB                   cross-gdb binary         (default: arm-none-eabi-gdb)
#
# OpenOCD backend overrides:
#   OPENOCD               openocd binary           (default: openocd)
#   OPENOCD_INTERFACE     interface config         (default: interface/jlink.cfg)
#   OPENOCD_TARGET        target config            (default: target/nrf52.cfg)
#   OPENOCD_TRANSPORT     transport                (default: swd)
set -euo pipefail

RUN_NRF52840_BACKEND="${RUN_NRF52840_BACKEND:-auto}"
NRF_TIMEOUT_MS="${NRF_TIMEOUT_MS:-60000}"
NRF_RETRIES="${NRF_RETRIES:-5}"

JLINK_GDB_SERVER="${JLINK_GDB_SERVER:-JLinkGDBServer}"
JLINK_DEVICE="${JLINK_DEVICE:-nRF52840_xxAA}"
JLINK_SPEED="${JLINK_SPEED:-4000}"
JLINK_PORT="${JLINK_PORT:-2331}"
GDB="${GDB:-arm-none-eabi-gdb}"

OPENOCD="${OPENOCD:-openocd}"
OPENOCD_INTERFACE="${OPENOCD_INTERFACE:-interface/jlink.cfg}"
OPENOCD_TARGET="${OPENOCD_TARGET:-target/nrf52.cfg}"
OPENOCD_TRANSPORT="${OPENOCD_TRANSPORT:-swd}"

flash_only=0
elf=""
while [ $# -gt 0 ]; do
    case "$1" in
        --flash-only) flash_only=1; shift ;;
        -h|--help) sed -n '2,60p' "$0"; exit 0 ;;
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

# OpenOCD's TCL `program`/`load_image` want a forward-slash path; bash paths
# already are, but normalise relative paths to absolute so the backend's cwd
# doesn't matter. GDB's `load` benefits from this too.
elf_abs="$(cd "$(dirname "$elf")" && pwd)/$(basename "$elf")"

# Pick a backend. `auto` (the default) prefers J-Link if both JLinkGDBServer
# and a cross-gdb are on PATH, since SEGGER's tooling talks natively to the
# on-board probe; otherwise we fall back to OpenOCD.
select_backend() {
    case "$RUN_NRF52840_BACKEND" in
        jlink|openocd) printf '%s\n' "$RUN_NRF52840_BACKEND" ;;
        auto)
            if command -v "$JLINK_GDB_SERVER" >/dev/null 2>&1 \
                && command -v "$GDB" >/dev/null 2>&1; then
                printf 'jlink\n'
            elif command -v "$OPENOCD" >/dev/null 2>&1; then
                printf 'openocd\n'
            else
                echo "run-nrf52840.sh: no debug-probe backend available." >&2
                echo "  Looked for J-Link ('$JLINK_GDB_SERVER' + '$GDB') and OpenOCD ('$OPENOCD')." >&2
                echo "  Enter the dev shell (nix develop .#arm-cortex-m4-gcc) or install one of them." >&2
                exit 127
            fi ;;
        *)
            echo "run-nrf52840.sh: invalid RUN_NRF52840_BACKEND='$RUN_NRF52840_BACKEND' (want jlink|openocd|auto)" >&2
            exit 2 ;;
    esac
}

backend="$(select_backend)"

case "$backend" in
    jlink)
        if ! command -v "$JLINK_GDB_SERVER" >/dev/null 2>&1; then
            echo "run-nrf52840.sh: '$JLINK_GDB_SERVER' not on PATH." >&2
            exit 127
        fi
        if ! command -v "$GDB" >/dev/null 2>&1; then
            echo "run-nrf52840.sh: '$GDB' not on PATH (need arm-none-eabi-gdb or override via GDB=...)." >&2
            exit 127
        fi ;;
    openocd)
        if ! command -v "$OPENOCD" >/dev/null 2>&1; then
            echo "run-nrf52840.sh: '$OPENOCD' not on PATH. Enter the dev shell (nix develop .#arm-cortex-m4-gcc) or install openocd." >&2
            exit 127
        fi ;;
esac

# Shared tempfiles. `log` collects backend stderr/chatter (only shown on
# final failure); `out` collects target semihosting output (only emitted
# on success so a failed attempt's partial output is discarded rather than
# interleaved with retries).
log="$(mktemp -t run-nrf52840.XXXXXX.log)"
out="$(mktemp -t run-nrf52840.XXXXXX.out)"
jlink_server_pid=0
cleanup() {
    if [ "$jlink_server_pid" -ne 0 ] && kill -0 "$jlink_server_pid" 2>/dev/null; then
        kill "$jlink_server_pid" 2>/dev/null || true
        wait "$jlink_server_pid" 2>/dev/null || true
    fi
    rm -f "$log" "$out"
}
trap cleanup EXIT

# ---- OpenOCD backend ----------------------------------------------------

# Adapter + transport + target wiring. Using inline `adapter driver` keeps us
# robust across OpenOCD versions where the bundled interface/jlink.cfg is a
# thin wrapper around exactly this.
openocd_common=(
    -c "adapter driver jlink"
    -c "transport select ${OPENOCD_TRANSPORT}"
    -f "${OPENOCD_TARGET}"
)

openocd_attempt() {
    if [ "$flash_only" -eq 1 ]; then
        "$OPENOCD" "${openocd_common[@]}" \
            -c "init" \
            -c "halt" \
            -c "program {${elf_abs}} verify reset" \
            -c "shutdown" \
            >"$out" 2>"$log"
    else
        "$OPENOCD" "${openocd_common[@]}" \
            -c "init" \
            -c "halt" \
            -c "program {${elf_abs}} verify" \
            -c "reset halt" \
            -c "arm semihosting enable" \
            -c "resume" \
            -c "wait_halt ${NRF_TIMEOUT_MS}" \
            -c "shutdown" \
            >"$out" 2>"$log"
    fi
}

# ---- J-Link backend (JLinkGDBServer + cross-gdb) ------------------------

# Spawn JLinkGDBServer in the background and poll the GDB TCP port until it
# accepts connections (using bash's /dev/tcp — no nc needed). Returns 0 with
# $jlink_server_pid set on success; non-zero on failure (with stderr/chatter
# appended to $log).
start_jlink_gdbserver() {
    "$JLINK_GDB_SERVER" \
        -device "$JLINK_DEVICE" \
        -if SWD \
        -speed "$JLINK_SPEED" \
        -port "$JLINK_PORT" \
        -singlerun \
        -nogui \
        -silent \
        -localhostonly 1 \
        >>"$log" 2>&1 &
    jlink_server_pid=$!
    local i
    for i in $(seq 1 100); do
        if (exec 3<>"/dev/tcp/127.0.0.1/${JLINK_PORT}") 2>/dev/null; then
            exec 3<&- 3>&-
            return 0
        fi
        if ! kill -0 "$jlink_server_pid" 2>/dev/null; then
            wait "$jlink_server_pid" 2>/dev/null || true
            jlink_server_pid=0
            return 1
        fi
        sleep 0.1
    done
    # Port never came up; kill the dangling server before reporting failure.
    kill "$jlink_server_pid" 2>/dev/null || true
    wait "$jlink_server_pid" 2>/dev/null || true
    jlink_server_pid=0
    return 1
}

stop_jlink_gdbserver() {
    # `-singlerun` makes the server exit on its own once GDB disconnects;
    # this is the belt-and-braces path for the failure cases above it.
    if [ "$jlink_server_pid" -ne 0 ]; then
        if kill -0 "$jlink_server_pid" 2>/dev/null; then
            kill "$jlink_server_pid" 2>/dev/null || true
        fi
        wait "$jlink_server_pid" 2>/dev/null || true
        jlink_server_pid=0
    fi
}

# Enforce NRF_TIMEOUT_MS on the J-Link run path (the OpenOCD path uses
# `wait_halt $NRF_TIMEOUT_MS` natively). 124 is coreutils `timeout`'s
# "command timed out" exit code, which we want to treat as a normal retry.
jlink_timeout_sec() {
    local s=$(( NRF_TIMEOUT_MS / 1000 ))
    [ "$s" -lt 1 ] && s=1
    printf '%s\n' "$s"
}

# GDB script. With `set logging redirect on`, GDB's own CLI output goes to
# the log file *instead of* stdout, while inferior I/O (the O-packet
# semihosting writes) stays on stdout — exactly what we want for the
# expected.txt diff. `monitor semihosting IOClient 2` forces J-Link to
# route SYS_WRITE through GDB O-packets (not its own telnet console, which
# is the default and would otherwise bypass our stdout entirely).
jlink_run_gdb() {
    local gdb_args=(
        -batch -q
        -ex "set confirm off"
        -ex "set pagination off"
        -ex "set logging file ${log}"
        -ex "set logging overwrite off"
        -ex "set logging redirect on"
        -ex "set logging enabled on"
        -ex "target remote :${JLINK_PORT}"
    )
    if [ "$flash_only" -eq 1 ]; then
        gdb_args+=(
            -ex "load"
            -ex "monitor reset"
            -ex "disconnect"
            -ex "quit"
        )
    else
        gdb_args+=(
            -ex "monitor semihosting enable"
            -ex "monitor semihosting IOClient 2"
            -ex "load"
            -ex "monitor reset"
            -ex "continue"
            -ex "quit"
        )
    fi
    if [ "$flash_only" -eq 1 ] || ! command -v timeout >/dev/null 2>&1; then
        "$GDB" "${gdb_args[@]}" "$elf_abs" >"$out"
    else
        timeout -k 5s "$(jlink_timeout_sec)s" "$GDB" "${gdb_args[@]}" "$elf_abs" >"$out"
    fi
}

jlink_attempt() {
    if ! start_jlink_gdbserver; then
        return 1
    fi
    local rc=0
    if ! jlink_run_gdb; then
        rc=$?
    fi
    stop_jlink_gdbserver
    return $rc
}

# ---- Driver: run the chosen backend with retries -----------------------

# Back-to-back debug-probe sessions can fail transiently — on the on-board
# J-Link in particular ("Registration failed: maximum number of connections
# on the device reached") it can take a few seconds for a stale session to
# clear after the previous attempt exits. We back off progressively
# (1s, 2s, 3s, …), discard each failed attempt's partial output, and only
# emit $out on success. The backend's chatter ($log) is shown on final
# failure.
attempt_fn=""
case "$backend" in
    jlink) attempt_fn=jlink_attempt ;;
    openocd) attempt_fn=openocd_attempt ;;
esac

if [ "$flash_only" -eq 1 ]; then
    echo "run-nrf52840.sh: flashing $elf_abs via $backend ..." >&2
fi

rc=0
for attempt in $(seq 1 "$NRF_RETRIES"); do
    : >"$out"
    : >"$log"
    if "$attempt_fn"; then
        cat "$out"
        if [ "$flash_only" -eq 1 ]; then
            echo "run-nrf52840.sh: flashed (and reset to run)." >&2
        fi
        exit 0
    else
        # $? inside the `else` branch is the failing attempt_fn's exit code;
        # outside the `if`/`else` it would reset to 0.
        rc=$?
    fi
    if [ "$attempt" -lt "$NRF_RETRIES" ]; then
        echo "run-nrf52840.sh: $backend attempt $attempt/$NRF_RETRIES failed (exit $rc); retrying in ${attempt}s..." >&2
        sleep "$attempt"
    fi
done

echo "run-nrf52840.sh: $backend failed after $NRF_RETRIES attempts (exit $rc). Log:" >&2
cat "$log" >&2
exit "$rc"
