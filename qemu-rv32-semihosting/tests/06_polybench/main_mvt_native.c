#include "polybench-harness.h"
#include <stdint.h>
#include <stdio.h>

extern uint32_t mvt_run(void);

int
main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;

  printf("PolyBench/mvt (MINI, native)\n");

  BENCH_START();
  uint32_t fp = mvt_run();
  BENCH_END("mvt");

  printf("fingerprint=%lu\n", (unsigned long)fp);
  printf("PASS: mvt kernel completed\n");
  return 0;
}
