/**
 * This version is stamped on May 10, 2016
 *
 * Contact:
 *   Louis-Noel Pouchet <pouchet.ohio-state.edu>
 *   Tomofumi Yuki <tomofumi.yuki.fr>
 *
 * Web address: http://polybench.sourceforge.net
 */
/* gemm.c: adapted from PolyBench/C 4.2.1 for bare-metal RISC-V */

#include <stdint.h>
#include <polybench.h>
#include "gemm.h"

void
gemm_init_array(int ni, int nj, int nk,
           DATA_TYPE *alpha,
           DATA_TYPE *beta,
           DATA_TYPE POLYBENCH_2D(C, NI, NJ, ni, nj),
           DATA_TYPE POLYBENCH_2D(A, NI, NK, ni, nk),
           DATA_TYPE POLYBENCH_2D(B, NK, NJ, nk, nj))
{
  int i, j;
  *alpha = 1.5;
  *beta = 1.2;
  for (i = 0; i < ni; i++)
    for (j = 0; j < nj; j++)
      C[i][j] = (DATA_TYPE)((i * j + 1) % ni) / ni;
  for (i = 0; i < ni; i++)
    for (j = 0; j < nk; j++)
      A[i][j] = (DATA_TYPE)(i * (j + 1) % nk) / nk;
  for (i = 0; i < nk; i++)
    for (j = 0; j < nj; j++)
      B[i][j] = (DATA_TYPE)(i * (j + 2) % nj) / nj;
}

static uint32_t
fingerprint_C(int ni, int nj, DATA_TYPE POLYBENCH_2D(C, NI, NJ, ni, nj))
{
  uint32_t fp = 0;
  for (int i = 0; i < ni; i++) {
    for (int j = 0; j < nj; j++) {
      DATA_TYPE v = C[i][j];
      if (v < 0)
        v = -v;
      fp += (uint32_t)(v * 1000.0);
    }
  }
  return fp;
}

void
gemm_kernel_gemm(int ni, int nj, int nk,
            DATA_TYPE alpha,
            DATA_TYPE beta,
            DATA_TYPE POLYBENCH_2D(C, NI, NJ, ni, nj),
            DATA_TYPE POLYBENCH_2D(A, NI, NK, ni, nk),
            DATA_TYPE POLYBENCH_2D(B, NK, NJ, nk, nj))
{
  int i, j, k;
#pragma scop
  for (i = 0; i < _PB_NI; i++) {
    for (j = 0; j < _PB_NJ; j++)
      C[i][j] *= beta;
    for (k = 0; k < _PB_NK; k++) {
      for (j = 0; j < _PB_NJ; j++)
        C[i][j] += alpha * A[i][k] * B[k][j];
    }
  }
#pragma endscop
}

uint32_t
gemm_run(void)
{
  int ni = NI;
  int nj = NJ;
  int nk = NK;

  DATA_TYPE alpha;
  DATA_TYPE beta;
  DATA_TYPE C[NI][NJ];
  DATA_TYPE A[NI][NK];
  DATA_TYPE B[NK][NJ];

  gemm_init_array(ni, nj, nk, &alpha, &beta, C, A, B);
  gemm_kernel_gemm(ni, nj, nk, alpha, beta, C, A, B);
  return fingerprint_C(ni, nj, C);
}
