#include "polybench-harness.h"
#include <stdint.h>
#include <stdio.h>

extern uint32_t gemm_run(void);

int
main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;

  printf("PolyBench/gemm (MINI, native)\n");

  BENCH_START();
  uint32_t fp = gemm_run();
  BENCH_END("gemm");

  printf("fingerprint=%lu\n", (unsigned long)fp);
  printf("PASS: gemm kernel completed\n");
  return 0;
}
