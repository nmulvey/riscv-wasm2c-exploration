#include "polybench-harness.h"
#include <stdio.h>
#include <stdint.h>
#include <stdio.h>

extern uint32_t mm2_run(void);

int
main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;

  printf("PolyBench/2mm (MINI, native)\n");

  BENCH_START();
  uint32_t fp = mm2_run();
  BENCH_END("2mm");

  printf("fingerprint=%lu\n", (unsigned long)fp);
  printf("PASS: 2mm kernel completed\n");
  return 0;
}
