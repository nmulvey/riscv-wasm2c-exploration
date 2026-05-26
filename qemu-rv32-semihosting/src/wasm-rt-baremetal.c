#include "wasm-rt.h"
#include <stdbool.h>
#include <stdint.h>

uint32_t wasm_rt_call_stack_depth = 0;
uint32_t wasm_rt_saved_call_stack_depth = 0;

/* WASM linear-memory backing store. Sized to fit several 64 KiB pages so
 * that wasm2c modules with a non-trivial stack + .data + .bss footprint
 * fit without overflowing. wasm_rt_allocate_memory points mem->data here.
 *
 * WASM_RT_HEAP_SIZE is overridable at compile time: QEMU's machines have
 * megabytes of RAM so the default is generous, but real targets (e.g. the
 * nRF52840's 256 KiB SRAM) need a smaller buffer to leave room for the
 * stack and .data/.bss. The Makefile's HEAP_SIZE knob feeds this. */
#ifndef WASM_RT_HEAP_SIZE
#define WASM_RT_HEAP_SIZE 262144
#endif
static uint8_t heap[WASM_RT_HEAP_SIZE];

void wasm_rt_allocate_memory(wasm_rt_memory_t* mem, uint64_t initial_pages, uint64_t max_pages,
                             bool is64, uint32_t page_size) {
    mem->page_size = page_size;
    mem->pages = initial_pages;
    mem->max_pages = max_pages;
    mem->size = initial_pages * page_size;
    mem->is64 = is64;
    mem->data = heap;
    mem->data_end = heap + mem->size;
}

void wasm_rt_free_memory(wasm_rt_memory_t* mem) { (void)mem; }

uint64_t wasm_rt_grow_memory(wasm_rt_memory_t* mem, uint64_t pages) {
    (void)mem;
    (void)pages;
    return 0xffffffff;
}

void wasm_rt_trap(wasm_rt_trap_t code) {
    (void)code;
    while (1) {
    }
}

void wasm_rt_init(void) {}
void wasm_rt_free(void) {}
void wasm_rt_init_thread(void) {}
void wasm_rt_free_thread(void) {}

bool wasm_rt_is_initialized(void) { return true; }

void __assert_func(const char* file, int line, const char* func, const char* expr) {
    (void)file;
    (void)line;
    (void)func;
    (void)expr;
    while (1) {
    }
}

int* __errno_location(void) {
    static int e = 0;
    return &e;
}

int __errno(void) { return 0; }

void halt(void) {
    while (1) {
    }
}

/* Function reference table support for wasm2c */

/* Function reference table support for wasm2c */
void wasm_rt_allocate_funcref_table(wasm_rt_funcref_table_t* table, uint32_t size,
                                    uint32_t max_size) {
    table->size = size;
    table->max_size = max_size;
    table->data = calloc(size, sizeof(wasm_rt_funcref_t));
    if (!table->data) {
        abort();
    }
}

void wasm_rt_free_funcref_table(wasm_rt_funcref_table_t* table) {
    if (table && table->data) {
        free(table->data);
        table->data = NULL;
    }
}
