#include "wasm-rt.h"
#include <stdbool.h>
#include <stdint.h>

uint32_t wasm_rt_call_stack_depth = 0;
uint32_t wasm_rt_saved_call_stack_depth = 0;

#ifndef NATIVE
#define UART0_THR ((volatile unsigned char*)0x10000000)

static void uart_putc(char c) {
    *UART0_THR = c;
}

static void uart_putuint(unsigned int n) {
    char buf[10];
    int i = 0;
    if (n == 0) { uart_putc('0'); return; }
    while (n > 0) { buf[i++] = '0' + (n % 10); n /= 10; }
    while (i > 0) uart_putc(buf[--i]);
}

int printf(const char* fmt, ...) {
    __builtin_va_list args;
    __builtin_va_start(args, fmt);
    for (const char* p = fmt; *p; p++) {
        if (*p == '%') {
            p++;
            if (*p == 'l') p++;  // skip 'l'
            if (*p == 'u') {
                uart_putuint(__builtin_va_arg(args, unsigned int));
            }
        } else {
            uart_putc(*p);
        }
    }
    __builtin_va_end(args);
    return 0;
}
#else
#include <stdio.h>
#endif

static uint8_t heap[65536];

void wasm_rt_allocate_memory(wasm_rt_memory_t* mem, uint64_t initial_pages,
                              uint64_t max_pages, bool is64, uint32_t page_size) {
    mem->page_size = page_size;
    mem->pages = initial_pages;
    mem->max_pages = max_pages;
    mem->size = initial_pages * page_size;
    mem->is64 = is64;
    mem->data = heap;
    mem->data_end = heap + mem->size;
}

void wasm_rt_free_memory(wasm_rt_memory_t* mem) {
    (void)mem;
}

uint64_t wasm_rt_grow_memory(wasm_rt_memory_t* mem, uint64_t pages) {
    (void)mem; (void)pages;
    return 0xffffffff;
}

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

int* __errno_location(void) {
    static int e = 0;
    return &e;
}

int __errno(void) { return 0; }

void halt(void) { while(1) {} }
