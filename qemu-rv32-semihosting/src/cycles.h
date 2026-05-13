#ifndef CYCLES_H
#define CYCLES_H

#include <stdint.h>

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

#ifdef BENCH
#include <stdio.h>

#define BENCH_START()                                                                              \
    uint64_t _bench_c0 = read_cycles();                                                            \
    uint64_t _bench_i0 = read_instret()

// `label` must be a string literal: it's concatenated into the format string
// because the project's printf in src/wasm-rt-baremetal.c only supports
// %u/%lu, not %s. Counters are truncated to 32 bits for the same reason
// (no %llu support).
//
// `instret` (retired instructions) is meaningful on any RV target.
// `rdcycle` requires a cycle-accurate backend; QEMU's `virt` machine isn't
// one and returns host-time-derived values, so under QEMU `instret` is the
// metric to compare. Both reads are kept here for future cycle-accurate
// targets where `rdcycle` will be the more interesting number.
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
