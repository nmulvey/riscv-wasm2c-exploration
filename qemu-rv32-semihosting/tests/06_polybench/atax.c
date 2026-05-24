/* Adapted from PolyBench/C 4.2.1 atax.c.
 *
 * Differences from upstream:
 *   - init_array / kernel_atax are no longer `static` (the WASM build
 *     re-exports them via --export-all, and the native harness calls
 *     them directly).
 *   - Upstream main() and print_array() are dropped: print_array uses
 *     %0.2lf which would force float-printf into the WASM module (no
 *     libc there). Instead we expose a single atax_run() entrypoint
 *     that owns the stack-allocated arrays and returns an integer
 *     fingerprint of y, so the native and WASM call paths are
 *     identical from the harness's point of view.
 *
 * Compile with -DPOLYBENCH_STACK_ARRAYS so atax_run owns the storage
 * (no malloc, no polybench.c). The dataset macro (-DMINI_DATASET / etc.)
 * is supplied by the Makefile.
 */

#include <stdint.h>

#include "atax.h"
#include <polybench.h>

void init_array(int m, int n, DATA_TYPE POLYBENCH_2D(A, M, N, m, n),
                DATA_TYPE POLYBENCH_1D(x, N, n)) {
    int i, j;
    DATA_TYPE fn;
    fn = (DATA_TYPE)n;

    for (i = 0; i < n; i++)
        x[i] = 1 + (i / fn);
    for (i = 0; i < m; i++)
        for (j = 0; j < n; j++)
            A[i][j] = (DATA_TYPE)((i + j) % n) / (5 * m);
}

void kernel_atax(int m, int n, DATA_TYPE POLYBENCH_2D(A, M, N, m, n),
                 DATA_TYPE POLYBENCH_1D(x, N, n), DATA_TYPE POLYBENCH_1D(y, N, n),
                 DATA_TYPE POLYBENCH_1D(tmp, M, m)) {
    int i, j;

#pragma scop
    for (i = 0; i < _PB_N; i++)
        y[i] = 0;
    for (i = 0; i < _PB_M; i++) {
        tmp[i] = SCALAR_VAL(0.0);
        for (j = 0; j < _PB_N; j++)
            tmp[i] = tmp[i] + A[i][j] * x[j];
        for (j = 0; j < _PB_N; j++)
            y[j] = y[j] + A[i][j] * tmp[i];
    }
#pragma endscop
}

/* Integer fingerprint of the live-out vector y.
 *
 * Replaces upstream's print_array (which formats doubles, requiring
 * float-printf — unavailable in the WASM module). We accumulate
 * |round(y[i] * 1000)| into a 32-bit sum: deterministic across
 * native and wasm2c since both lower to IEEE-754 f64. */
static uint32_t fingerprint_y(int n, DATA_TYPE POLYBENCH_1D(y, N, n)) {
    uint32_t fp = 0;
    for (int i = 0; i < n; i++) {
        DATA_TYPE v = y[i];
        if (v < 0)
            v = -v;
        fp += (uint32_t)(v * 1000.0);
    }
    return fp;
}

/* Single entry point used by both main_native.c and (via wasm2c)
 * main_wasm.c. Owns all working storage on the stack, so the wasm
 * module needs no host-side memory plumbing. */
uint32_t atax_run(void) {
    DATA_TYPE A[M][N];
    DATA_TYPE x[N];
    DATA_TYPE y[N];
    DATA_TYPE tmp[M];

    init_array(M, N, A, x);
    kernel_atax(M, N, A, x, y, tmp);
    return fingerprint_y(N, y);
}
