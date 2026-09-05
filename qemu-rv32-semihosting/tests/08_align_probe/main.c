#include <stdio.h>
#include <stdint.h>
#include <string.h>

static uint8_t sandbox_mem[256] __attribute__((aligned(16))) = {
    0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
    0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,
};

#define MEM_ADDR_MEMOP(base, addr) \
    ((uint8_t *)(uintptr_t)((uint8_t *)(base) + (uint32_t)(addr)))

__attribute__((noinline))
uint32_t load_i32_optimized(uint32_t addr) {
    volatile uint32_t *p = (volatile uint32_t *)MEM_ADDR_MEMOP(sandbox_mem, addr);
    return *p;
}

extern void install_trap_vector(void);
extern volatile uint32_t g_trapped;
extern volatile uint32_t g_mcause;

static void try_load(uint32_t addr) {
    g_trapped = 0;
    printf("misaligned optimized addr=%lu: ", (unsigned long)addr);
    fflush(stdout);
    uint32_t v = load_i32_optimized(addr);
    if (g_trapped) {
        printf("TRAP mcause=%lu", (unsigned long)g_mcause);
        if ((g_mcause & 0x7fffffff) == 4) printf(" (load address misaligned)");
        printf("\n");
    } else {
        printf("0x%08lx  (survived)\n", (unsigned long)v);
    }
}

int main(int argc, char* argv[]) {
    (void)argc; (void)argv;

    install_trap_vector();

    printf("== alignment probe start ==\n");
    printf("aligned optimized addr=0: 0x%08lx\n", (unsigned long)load_i32_optimized(0));

    for (uint32_t a = 1; a <= 3; a++)
        try_load(a);

    printf("== done ==\n");
    return 0;
}
