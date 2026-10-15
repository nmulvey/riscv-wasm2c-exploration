#include <stdint.h>
#include <string.h>

static uint8_t sandbox_mem[256] __attribute__((aligned(16))) = {
    0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
    0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,
};

#define MEM_ADDR_MEMOP(base, addr) \
    ((uint8_t *)(uintptr_t)((uint8_t *)(base) + (uint32_t)(addr)))

__attribute__((noinline))
uint32_t load_i32_defensive(uint32_t addr) {
    uint32_t v;
    __builtin_memcpy(&v, MEM_ADDR_MEMOP(sandbox_mem, addr), sizeof(v));
    return v;
}

__attribute__((noinline))
uint32_t load_i32_optimized(uint32_t addr) {
    volatile uint32_t *p = (volatile uint32_t *)MEM_ADDR_MEMOP(sandbox_mem, addr);
    return *p;
}

extern void semi_puts(const char *s);
extern void semi_puthex(uint32_t v);

int main(void) {
    semi_puts("== alignment probe start ==\n");

    semi_puts("aligned defensive addr=0: ");
    semi_puthex(load_i32_defensive(0));
    semi_puts("\n");

    semi_puts("aligned optimized addr=0: ");
    semi_puthex(load_i32_optimized(0));
    semi_puts("\n");

    for (uint32_t a = 1; a <= 3; a++) {
        semi_puts("misaligned defensive addr=");
        semi_puthex(a);
        semi_puts(": ");
        uint32_t v = load_i32_defensive(a);
        semi_puthex(v);
        semi_puts("  (survived)\n");
    }

    semi_puts("== all misaligned loads completed, no trap ==\n");
    return 0;
}
