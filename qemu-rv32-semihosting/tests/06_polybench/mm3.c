/**
 * This version is stamped on May 10, 2016
 *
 * Contact:
 *   Louis-Noel Pouchet <pouchet.ohio-state.edu>
 *   Tomofumi Yuki <tomofumi.yuki.fr>
 *
 * Web address: http://polybench.sourceforge.net
 */
/* mm3.c: adapted from PolyBench/C 4.2.1 3mm.c for bare-metal RISC-V
 *
 * Differences from upstream:
 *   - init_array, kernel_3mm are no longer `static`
 *   - Upstream main() and print_array() are dropped; replaced with integer
 *     fingerprinting of output matrix G for WASM compatibility.
 *
 * Compile with -DPOLYBENCH_STACK_ARRAYS so mm3_run owns the storage.
 * The dataset macro (-DMINI_DATASET / etc.) is supplied by the Makefile.
 */

#include <stdint.h>
#include <polybench.h>
#include "mm3.h"

/* Array initialization. */
void
mm3_init_array(int ni, int nj, int nk, int nl, int nm,
           DATA_TYPE POLYBENCH_2D(A, NI, NK, ni, nk),
           DATA_TYPE POLYBENCH_2D(B, NK, NJ, nk, nj),
           DATA_TYPE POLYBENCH_2D(C, NJ, NM, nj, nm),
           DATA_TYPE POLYBENCH_2D(D, NM, NL, nm, nl))
{
  int i, j;

  for (i = 0; i < ni; i++)
    for (j = 0; j < nk; j++)
      A[i][j] = (DATA_TYPE)((i * j + 1) % ni) / (5 * ni);
  for (i = 0; i < nk; i++)
    for (j = 0; j < nj; j++)
      B[i][j] = (DATA_TYPE)((i * (j + 1) + 2) % nj) / (5 * nj);
  for (i = 0; i < nj; i++)
    for (j = 0; j < nm; j++)
      C[i][j] = (DATA_TYPE)(i * (j + 3) % nl) / (5 * nl);
  for (i = 0; i < nm; i++)
    for (j = 0; j < nl; j++)
      D[i][j] = (DATA_TYPE)((i * (j + 2) + 2) % nk) / (5 * nk);
}

/* Integer fingerprint of the live-out matrix G. */
static uint32_t
fingerprint_G(int ni, int nl, DATA_TYPE POLYBENCH_2D(G, NI, NL, ni, nl))
{
  uint32_t fp = 0;
  for (int i = 0; i < ni; i++) {
    for (int j = 0; j < nl; j++) {
      DATA_TYPE v = G[i][j];
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
mm3_kernel_3mm(int ni, int nj, int nk, int nl, int nm,
           DATA_TYPE POLYBENCH_2D(E, NI, NJ, ni, nj),
           DATA_TYPE POLYBENCH_2D(A, NI, NK, ni, nk),
           DATA_TYPE POLYBENCH_2D(B, NK, NJ, nk, nj),
           DATA_TYPE POLYBENCH_2D(F, NJ, NL, nj, nl),
           DATA_TYPE POLYBENCH_2D(C, NJ, NM, nj, nm),
           DATA_TYPE POLYBENCH_2D(D, NM, NL, nm, nl),
           DATA_TYPE POLYBENCH_2D(G, NI, NL, ni, nl))
{
  int i, j, k;

#pragma scop
  /* E := A*B */
  for (i = 0; i < _PB_NI; i++)
    for (j = 0; j < _PB_NJ; j++) {
      E[i][j] = SCALAR_VAL(0.0);
      for (k = 0; k < _PB_NK; ++k)
        E[i][j] += A[i][k] * B[k][j];
    }
  /* F := C*D */
  for (i = 0; i < _PB_NJ; i++)
    for (j = 0; j < _PB_NL; j++) {
      F[i][j] = SCALAR_VAL(0.0);
      for (k = 0; k < _PB_NM; ++k)
        F[i][j] += C[i][k] * D[k][j];
    }
  /* G := E*F */
  for (i = 0; i < _PB_NI; i++)
    for (j = 0; j < _PB_NL; j++) {
      G[i][j] = SCALAR_VAL(0.0);
      for (k = 0; k < _PB_NJ; ++k)
        G[i][j] += E[i][k] * F[k][j];
    }
#pragma endscop
}

/* Single entry point used by both main_native.c and (via wasm2c)
 * main_wasm.c. Owns all working storage on the stack. */
uint32_t
mm3_run(void)
{
  /* Retrieve problem size. */
  int ni = NI;
  int nj = NJ;
  int nk = NK;
  int nl = NL;
  int nm = NM;

  /* Variable declaration/allocation. */
  DATA_TYPE E[NI][NJ];
  DATA_TYPE A[NI][NK];
  DATA_TYPE B[NK][NJ];
  DATA_TYPE F[NJ][NL];
  DATA_TYPE C[NJ][NM];
  DATA_TYPE D[NM][NL];
  DATA_TYPE G[NI][NL];

  /* Initialize array(s). */
  mm3_init_array(ni, nj, nk, nl, nm, A, B, C, D);

  /* Run kernel. */
  mm3_kernel_3mm(ni, nj, nk, nl, nm, E, A, B, F, C, D, G);

  /* Return fingerprint of G. */
  return fingerprint_G(ni, nl, G);
}
