#include "mm3.wasm.h"
#include "polybench-harness.h"
#include <stdint.h>
#include <stdio.h>

int
main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;

  printf("PolyBench/3mm (MINI, wasm)\n");

  wasm_rt_init();

  w2c_mm3 instance;
  wasm2c_mm3_instantiate(&instance);

  BENCH_START();
  uint32_t fp = w2c_mm3_mm3_run(&instance);
  BENCH_END("3mm");

  printf("fingerprint=%lu\n", (unsigned long)fp);
  printf("PASS: 3mm kernel completed\n");
  return 0;
}
