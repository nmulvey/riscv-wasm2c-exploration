#ifndef POLYBENCH_HARNESS_H
#define POLYBENCH_HARNESS_H

#include <stdint.h>

static inline uint64_t read_rdcycle(void) {
    uint32_t lo, hi, hi_again;
    do {
        asm volatile("csrrs %0, 0xc80, x0" : "=r"(hi));
        asm volatile("csrrs %0, 0xc00, x0" : "=r"(lo));
        asm volatile("csrrs %0, 0xc80, x0" : "=r"(hi_again));
    } while (hi != hi_again);
    return ((uint64_t)hi << 32) | lo;
}

#endif
