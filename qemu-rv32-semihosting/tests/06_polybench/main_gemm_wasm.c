#include "gemm.wasm.h"
#include "polybench-harness.h"
#include <stdint.h>
#include <stdio.h>

int
main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;

  printf("PolyBench/gemm (MINI, wasm)\n");

  wasm_rt_init();

  w2c_gemm instance;
  wasm2c_gemm_instantiate(&instance);

  BENCH_START();
  uint32_t fp = w2c_gemm_gemm_run(&instance);
  BENCH_END("gemm");

  printf("fingerprint=%lu\n", (unsigned long)fp);
  printf("PASS: gemm kernel completed\n");
  return 0;
}
