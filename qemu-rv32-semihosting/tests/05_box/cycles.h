#ifndef BOX_CYCLES_H
#define BOX_CYCLES_H

#include "../../src/cycles.h"
#include <stdio.h>

/* src/cycles.h provides the architecture-specific counter implementation. */
#undef BENCH_START
#undef BENCH_END

static uint64_t _bench_start;

#define BENCH_START() (_bench_start = read_cycles())
#define BENCH_END(name)                                                                            \
    do {                                                                                           \
        uint64_t _bench_end = read_cycles();                                                       \
        uint64_t _cycles = _bench_end - _bench_start;                                              \
        printf("Cycles (%s): %llu\n", name, (unsigned long long)_cycles);                          \
    } while (0)

#endif
