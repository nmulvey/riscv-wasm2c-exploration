#include "polybench-harness.h"
#include <stdint.h>
#include <stdio.h>

extern uint32_t mm3_run(void);

int
main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;

  printf("PolyBench/3mm (MINI, native)\n");

  BENCH_START();
  uint32_t fp = mm3_run();
  BENCH_END("3mm");

  printf("fingerprint=%lu\n", (unsigned long)fp);
  printf("PASS: 3mm kernel completed\n");
  return 0;
}
