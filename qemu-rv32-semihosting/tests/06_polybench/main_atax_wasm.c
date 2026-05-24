#include "atax.wasm.h"
#include "cycles.h"
#include <stdint.h>
#include <stdio.h>

int main(int argc, char* argv[]) {
    (void)argc;
    (void)argv;

    printf("PolyBench/atax (MINI, wasm)\n");

    wasm_rt_init();

    w2c_atax instance;
    /* atax.wasm has no imports — wasm2c emits a 1-arg instantiate(). */
    wasm2c_atax_instantiate(&instance);

    BENCH_START();
    uint32_t fp = w2c_atax_atax_run(&instance);
    BENCH_END("atax");

    printf("fingerprint=%lu\n", (unsigned long)fp);
    printf("PASS: atax kernel completed\n");
    return 0;
}
