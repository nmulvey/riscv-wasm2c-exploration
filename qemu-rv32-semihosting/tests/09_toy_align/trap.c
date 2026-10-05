#include <stdint.h>

volatile uint32_t g_trapped = 0;
volatile uint32_t g_mcause = 0;
volatile uint32_t g_trap_count = 0;

#if defined(__riscv)

void trap_handler(void);

void install_trap_vector(void) {
    __asm__ volatile("csrw mtvec, %0" ::"r"((uintptr_t)&trap_handler));
}

__attribute__((naked, aligned(4))) void trap_handler(void) {
    __asm__ volatile("addi sp, sp, -16\n"
                     "sw   t0, 0(sp)\n"
                     "sw   t1, 4(sp)\n"
                     "sw   t2, 8(sp)\n"
                     "csrr t0, mcause\n"
                     "la   t1, g_mcause\n"
                     "sw   t0, 0(t1)\n"
                     "li   t0, 1\n"
                     "la   t1, g_trapped\n"
                     "sw   t0, 0(t1)\n"
                     "la   t1, g_trap_count\n"
                     "lw   t0, 0(t1)\n"
                     "addi t0, t0, 1\n"
                     "sw   t0, 0(t1)\n"
                     "csrr t0, mepc\n"
                     "lhu  t1, 0(t0)\n"
                     "andi t1, t1, 3\n"
                     "li   t2, 3\n"
                     "addi t0, t0, 2\n"
                     "bne  t1, t2, 1f\n"
                     "addi t0, t0, 2\n"
                     "1:\n"
                     "csrw mepc, t0\n"
                     "lw   t0, 0(sp)\n"
                     "lw   t1, 4(sp)\n"
                     "lw   t2, 8(sp)\n"
                     "addi sp, sp, 16\n"
                     "mret\n");
}
#elif defined(__arm__) || defined(__thumb__)
void install_trap_vector(void) {}
#else
#error "unsupported target architecture"
#endif
