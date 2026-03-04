#include "wasm-rt.h"

void wasm_rt_trap(wasm_rt_trap_t trap) {
    while(1) {}
}

void __assert_func(const char* file, int line, const char* func, const char* expr) {
    while(1) {}
}