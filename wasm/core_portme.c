#include "coremark.h"
#include "core_portme.h"
#include <stdint.h>

#if VALIDATION_RUN
volatile ee_s32 seed1_volatile = 0x3415;
volatile ee_s32 seed2_volatile = 0x3415;
volatile ee_s32 seed3_volatile = 0x66;
#endif
#if PERFORMANCE_RUN
volatile ee_s32 seed1_volatile = 0x0;
volatile ee_s32 seed2_volatile = 0x0;
volatile ee_s32 seed3_volatile = 0x66;
#endif
#if PROFILE_RUN
volatile ee_s32 seed1_volatile = 0x8;
volatile ee_s32 seed2_volatile = 0x8;
volatile ee_s32 seed3_volatile = 0x8;
#endif
volatile ee_s32 seed4_volatile = ITERATIONS;
volatile ee_s32 seed5_volatile = 0;

static uint32_t start_time_val, stop_time_val;
static uint32_t tick = 0;

void start_time(void) { start_time_val = tick++; }
void stop_time(void)  { stop_time_val = tick++; }

CORE_TICKS get_time(void) {
    return (CORE_TICKS)(stop_time_val - start_time_val);
}

secs_ret time_in_secs(CORE_TICKS ticks) {
    return ((secs_ret)ticks) / (secs_ret)1000;
}

ee_u32 default_num_contexts = 1;

void portable_init(core_portable *p, int *argc, char *argv[]) {
    (void)argc;
    (void)argv;
    p->portable_id = 1;
}

void portable_fini(core_portable *p) {
    p->portable_id = 0;
}

int ee_printf(const char *fmt, ...) { return 0; }
