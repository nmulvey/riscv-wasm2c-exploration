#include "cycles.h"
#include <stdint.h>
#include <stdio.h>

extern uint32_t atax_run(void);

int main(int argc, char* argv[]) {
    (void)argc;
    (void)argv;

    printf("PolyBench/atax (MINI, native)\n");

    BENCH_START();
    uint32_t fp = atax_run();
    BENCH_END("atax");

    printf("fingerprint=%lu\n", (unsigned long)fp);
    printf("PASS: atax kernel completed\n");
    return 0;
}
