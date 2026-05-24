/**
 * This version is stamped on May 10, 2016
 *
 * Contact:
 *   Louis-Noel Pouchet <pouchet.ohio-state.edu>
 *   Tomofumi Yuki <tomofumi.yuki.fr>
 *
 * Web address: http://polybench.sourceforge.net
 */
/* mm2.c: adapted from PolyBench/C 4.2.1 2mm.c for bare-metal RISC-V
 *
 * Differences from upstream:
 *   - init_array, kernel_2mm, and fingerprint_D are no longer `static`
 *     (needed for test harness / WASM re-export).
 *   - Upstream main() and print_array() are dropped: print_array uses
 *     %0.2lf which would force float-printf into the WASM module (no
 *     libc there). Instead we expose a single mm2_run() entrypoint
 *     that owns the stack-allocated arrays and returns an integer
 *     fingerprint of D.
 *
 * Compile with -DPOLYBENCH_STACK_ARRAYS so mm2_run owns the storage
 * (no malloc, no polybench.c). The dataset macro (-DMINI_DATASET / etc.)
 * is supplied by the Makefile.
 */

#include <stdint.h>
#include <polybench.h>
#include "mm2.h"

/* Array initialization. */
void
mm2_init_array(int ni, int nj, int nk, int nl,
           DATA_TYPE *alpha,
           DATA_TYPE *beta,
           DATA_TYPE POLYBENCH_2D(A, NI, NK, ni, nk),
           DATA_TYPE POLYBENCH_2D(B, NK, NJ, nk, nj),
           DATA_TYPE POLYBENCH_2D(C, NJ, NL, nj, nl),
           DATA_TYPE POLYBENCH_2D(D, NI, NL, ni, nl))
{
  int i, j;

  *alpha = 1.5;
  *beta = 1.2;
  for (i = 0; i < ni; i++)
    for (j = 0; j < nk; j++)
      A[i][j] = (DATA_TYPE)((i * j + 1) % ni) / ni;
  for (i = 0; i < nk; i++)
    for (j = 0; j < nj; j++)
      B[i][j] = (DATA_TYPE)(i * (j + 1) % nj) / nj;
  for (i = 0; i < nj; i++)
    for (j = 0; j < nl; j++)
      C[i][j] = (DATA_TYPE)((i * (j + 3) + 1) % nl) / nl;
  for (i = 0; i < ni; i++)
    for (j = 0; j < nl; j++)
      D[i][j] = (DATA_TYPE)(i * (j + 2) % nk) / nk;
}

/* Integer fingerprint of the live-out matrix D.
 *
 * Replaces upstream's print_array (which formats doubles, requiring
 * float-printf — unavailable in the WASM module). We accumulate
 * |round(D[i][j] * 1000)| into a 32-bit sum: deterministic across
 * native and wasm2c since both lower to IEEE-754 f64. */
static uint32_t
fingerprint_D(int ni, int nl, DATA_TYPE POLYBENCH_2D(D, NI, NL, ni, nl))
{
  uint32_t fp = 0;
  for (int i = 0; i < ni; i++) {
    for (int j = 0; j < nl; j++) {
      DATA_TYPE v = D[i][j];
      if (v < 0)
        v = -v;
      fp += (uint32_t)(v * 1000.0);
    }
  }
  return fp;
}

/* Main computational kernel. The whole function will be timed,
   including the call and return. */
void
mm2_kernel_2mm(int ni, int nj, int nk, int nl,
           DATA_TYPE alpha,
           DATA_TYPE beta,
           DATA_TYPE POLYBENCH_2D(tmp, NI, NJ, ni, nj),
           DATA_TYPE POLYBENCH_2D(A, NI, NK, ni, nk),
           DATA_TYPE POLYBENCH_2D(B, NK, NJ, nk, nj),
           DATA_TYPE POLYBENCH_2D(C, NJ, NL, nj, nl),
           DATA_TYPE POLYBENCH_2D(D, NI, NL, ni, nl))
{
  int i, j, k;

#pragma scop
  /* D := alpha*A*B*C + beta*D */
  for (i = 0; i < _PB_NI; i++)
    for (j = 0; j < _PB_NJ; j++) {
      tmp[i][j] = SCALAR_VAL(0.0);
      for (k = 0; k < _PB_NK; ++k)
        tmp[i][j] += alpha * A[i][k] * B[k][j];
    }
  for (i = 0; i < _PB_NI; i++)
    for (j = 0; j < _PB_NL; j++) {
      D[i][j] *= beta;
      for (k = 0; k < _PB_NJ; ++k)
        D[i][j] += tmp[i][k] * C[k][j];
    }
#pragma endscop
}

/* Single entry point used by both main_native.c and (via wasm2c)
 * main_wasm.c. Owns all working storage on the stack, so the wasm
 * module needs no host-side memory plumbing. */
uint32_t
mm2_run(void)
{
  /* Retrieve problem size. */
  int ni = NI;
  int nj = NJ;
  int nk = NK;
  int nl = NL;

  /* Variable declaration/allocation. */
  DATA_TYPE alpha;
  DATA_TYPE beta;
  DATA_TYPE tmp[NI][NJ];
  DATA_TYPE A[NI][NK];
  DATA_TYPE B[NK][NJ];
  DATA_TYPE C[NJ][NL];
  DATA_TYPE D[NI][NL];

  /* Initialize array(s). */
  mm2_init_array(ni, nj, nk, nl, &alpha, &beta, A, B, C, D);

  /* Run kernel. */
  mm2_kernel_2mm(ni, nj, nk, nl, alpha, beta, tmp, A, B, C, D);

  /* Return fingerprint of D. */
  return fingerprint_D(ni, nl, D);
}
