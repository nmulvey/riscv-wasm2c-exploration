#include "mvt.wasm.h"
#include "polybench-harness.h"
#include <stdint.h>
#include <stdio.h>

int
main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;

  printf("PolyBench/mvt (MINI, wasm)\n");

  wasm_rt_init();

  w2c_mvt instance;
  wasm2c_mvt_instantiate(&instance);

  BENCH_START();
  uint32_t fp = w2c_mvt_mvt_run(&instance);
  BENCH_END("mvt");

  printf("fingerprint=%lu\n", (unsigned long)fp);
  printf("PASS: mvt kernel completed\n");
  return 0;
}
