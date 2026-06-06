#include "mm2.wasm.h"
#include "polybench-harness.h"
#include <stdint.h>
#include <stdio.h>

int
main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;

  printf("PolyBench/2mm (MINI, wasm)\n");

  wasm_rt_init();

  w2c_mm2 instance;
  /* mm2.wasm has no imports — wasm2c emits a 1-arg instantiate(). */
  wasm2c_mm2_instantiate(&instance);

  BENCH_START();
  uint32_t fp = w2c_mm2_mm2_run(&instance);
  BENCH_END("2mm");

  printf("fingerprint=%lu\n", (unsigned long)fp);
  printf("PASS: 2mm kernel completed\n");
  return 0;
}
