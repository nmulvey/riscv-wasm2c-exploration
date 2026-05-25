#ifndef CYCLES_H
#define CYCLES_H

#include <stdint.h>
#include <stdio.h>

static inline uint64_t read_rdcycle(void) {
    uint32_t lo, hi, hi_again;
    do {
        asm volatile("csrrs %0, 0xc80, x0" : "=r"(hi));
        asm volatile("csrrs %0, 0xc00, x0" : "=r"(lo));
        asm volatile("csrrs %0, 0xc80, x0" : "=r"(hi_again));
    } while (hi != hi_again);
    return ((uint64_t)hi << 32) | lo;
}

static uint64_t _bench_start;

#define BENCH_START() (_bench_start = read_rdcycle())
#define BENCH_END(name) do { \
    uint64_t _bench_end = read_rdcycle(); \
    uint64_t _cycles = _bench_end - _bench_start; \
    printf("Cycles (%s): %llu\n", name, (unsigned long long)_cycles); \
} while(0)

#endif
