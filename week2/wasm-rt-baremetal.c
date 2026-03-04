#include "wasm-rt.h"
#include <stdbool.h>
#include <stdint.h>

WASM_RT_THREAD_LOCAL uint32_t wasm_rt_call_stack_depth = 0;
WASM_RT_THREAD_LOCAL uint32_t wasm_rt_saved_call_stack_depth = 0;

void wasm_rt_trap(wasm_rt_trap_t code) {
    (void)code;
    while(1) {}
}

void wasm_rt_init(void)        {}
void wasm_rt_free(void)        {}
void wasm_rt_init_thread(void) {}
void wasm_rt_free_thread(void) {}

bool wasm_rt_is_initialized(void) { return true; }

void __assert_func(const char* file, int line,
                   const char* func, const char* expr) {
    (void)file; (void)line; (void)func; (void)expr;
    while(1) {}
}
