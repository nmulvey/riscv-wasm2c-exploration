#ifndef CYCLES_H
#define CYCLES_H

#include <stdint.h>

#if defined(__riscv)

// RV32 reads of 64-bit performance counters require sampling the high half
// twice and retrying if the low half rolls over between them.

static inline uint64_t read_cycles(void) {
    uint32_t hi, lo, tmp;
    asm volatile("1: rdcycleh %0\n"
                 "   rdcycle  %1\n"
                 "   rdcycleh %2\n"
                 "   bne %0, %2, 1b"
                 : "=&r"(hi), "=&r"(lo), "=&r"(tmp));
    return ((uint64_t)hi << 32) | lo;
}

static inline uint64_t read_instret(void) {
    uint32_t hi, lo, tmp;
    asm volatile("1: rdinstreth %0\n"
                 "   rdinstret  %1\n"
                 "   rdinstreth %2\n"
                 "   bne %0, %2, 1b"
                 : "=&r"(hi), "=&r"(lo), "=&r"(tmp));
    return ((uint64_t)hi << 32) | lo;
}

#elif defined(__arm__) || defined(__thumb__)

// ARMv7-M+ exposes a 32-bit free-running cycle counter via DWT->CYCCNT.
// It's gated by two unlocks: CoreDebug->DEMCR.TRCENA and DWT->CTRL.CYCCNTENA.
// We do them lazily on first read so callers don't need a crt0 hook.
//
// There is no architectural "instructions retired" counter on Cortex-M;
// read_instret returns 0 and BENCH output should be interpreted accordingly.

#define _CYCLES_DEMCR (*(volatile uint32_t*)0xE000EDFCu)
#define _CYCLES_DWT_CTRL (*(volatile uint32_t*)0xE0001000u)
#define _CYCLES_DWT_CYCCNT (*(volatile uint32_t*)0xE0001004u)
#define _CYCLES_DEMCR_TRCENA (1u << 24)
#define _CYCLES_DWT_CYCCNTENA (1u << 0)

static inline uint64_t read_cycles(void) {
    if (!(_CYCLES_DWT_CTRL & _CYCLES_DWT_CYCCNTENA)) {
        _CYCLES_DEMCR |= _CYCLES_DEMCR_TRCENA;
        _CYCLES_DWT_CYCCNT = 0;
        _CYCLES_DWT_CTRL |= _CYCLES_DWT_CYCCNTENA;
    }
    return (uint64_t)_CYCLES_DWT_CYCCNT;
}

static inline uint64_t read_instret(void) { return 0; }

#else
#error "cycles.h: no performance-counter implementation for this target"
#endif

#ifdef BENCH
#include <stdio.h>

#define BENCH_START()                                                                              \
    uint64_t _bench_c0 = read_cycles();                                                            \
    uint64_t _bench_i0 = read_instret()

// Counters are truncated to 32 bits to keep the format string simple; for
// these benchmarks the deltas comfortably fit.
//
// `instret` (retired instructions) is meaningful on RISC-V; on ARM Cortex-M
// there is no standard counter and we report 0.
// `rdcycle` (RV) / DWT.CYCCNT (ARM) requires a cycle-accurate backend; QEMU's
// `virt` / `mps2-*` machines aren't one and return host-time-derived values,
// so under QEMU `instret` is the metric to compare on RV. Both reads are
// kept here for future cycle-accurate targets where `rdcycle` will be the
// more interesting number.
#define BENCH_END(label)                                                                           \
    do {                                                                                           \
        uint32_t _c = (uint32_t)(read_cycles() - _bench_c0);                                       \
        uint32_t _i = (uint32_t)(read_instret() - _bench_i0);                                      \
        printf("[bench " label "] cycles=%lu instret=%lu\n", (unsigned long)_c,                    \
               (unsigned long)_i);                                                                 \
    } while (0)
#else
#define BENCH_START() ((void)0)
#define BENCH_END(label) ((void)0)
#endif

#endif
