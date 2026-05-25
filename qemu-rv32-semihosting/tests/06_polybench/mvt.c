/**
 * This version is stamped on May 10, 2016
 *
 * Contact:
 *   Louis-Noel Pouchet <pouchet.ohio-state.edu>
 *   Tomofumi Yuki <tomofumi.yuki.fr>
 *
 * Web address: http://polybench.sourceforge.net
 */
/* mvt.c: adapted from PolyBench/C 4.2.1 for bare-metal RISC-V */

#include <stdint.h>
#include <polybench.h>
#include "mvt.h"

void
mvt_init_array(int n,
           DATA_TYPE POLYBENCH_1D(x1, N, n),
           DATA_TYPE POLYBENCH_1D(x2, N, n),
           DATA_TYPE POLYBENCH_1D(y_1, N, n),
           DATA_TYPE POLYBENCH_1D(y_2, N, n),
           DATA_TYPE POLYBENCH_2D(A, N, N, n, n))
{
  int i, j;
  for (i = 0; i < n; i++) {
    x1[i] = (DATA_TYPE)(i % n) / n;
    x2[i] = (DATA_TYPE)((i + 1) % n) / n;
    y_1[i] = (DATA_TYPE)((i + 3) % n) / n;
    y_2[i] = (DATA_TYPE)((i + 4) % n) / n;
    for (j = 0; j < n; j++)
      A[i][j] = (DATA_TYPE)(i * j % n) / n;
  }
}

static uint32_t
fingerprint_xy(int n, DATA_TYPE POLYBENCH_1D(x1, N, n),
               DATA_TYPE POLYBENCH_1D(x2, N, n))
{
  uint32_t fp = 0;
  for (int i = 0; i < n; i++) {
    DATA_TYPE v = x1[i];
    if (v < 0)
      v = -v;
    fp += (uint32_t)(v * 1000.0);
    v = x2[i];
    if (v < 0)
      v = -v;
    fp += (uint32_t)(v * 1000.0);
  }
  return fp;
}

void
mvt_kernel_mvt(int n,
           DATA_TYPE POLYBENCH_1D(x1, N, n),
           DATA_TYPE POLYBENCH_1D(x2, N, n),
           DATA_TYPE POLYBENCH_1D(y_1, N, n),
           DATA_TYPE POLYBENCH_1D(y_2, N, n),
           DATA_TYPE POLYBENCH_2D(A, N, N, n, n))
{
  int i, j;
#pragma scop
  for (i = 0; i < _PB_N; i++)
    for (j = 0; j < _PB_N; j++)
      x1[i] = x1[i] + A[i][j] * y_1[j];
  for (i = 0; i < _PB_N; i++)
    for (j = 0; j < _PB_N; j++)
      x2[i] = x2[i] + A[j][i] * y_2[j];
#pragma endscop
}

uint32_t
mvt_run(void)
{
  int n = N;

  DATA_TYPE x1[N];
  DATA_TYPE x2[N];
  DATA_TYPE y_1[N];
  DATA_TYPE y_2[N];
  DATA_TYPE A[N][N];

  mvt_init_array(n, x1, x2, y_1, y_2, A);
  mvt_kernel_mvt(n, x1, x2, y_1, y_2, A);
  return fingerprint_xy(n, x1, x2);
}
