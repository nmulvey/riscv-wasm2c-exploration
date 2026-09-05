#include <stdint.h>

volatile uint32_t g_trapped = 0;
volatile uint32_t g_mcause = 0;

void trap_handler(void);

void install_trap_vector(void) {
    __asm__ volatile("csrw mtvec, %0" :: "r"((uintptr_t)&trap_handler));
}

void trap_dispatch(uintptr_t mcause, uintptr_t mepc, uintptr_t *mepc_out) {
    g_mcause = (uint32_t)mcause;
    g_trapped = 1;
    uint16_t insn = *(volatile uint16_t *)mepc;
    uintptr_t step = ((insn & 0x3) == 0x3) ? 4 : 2;
    *mepc_out = mepc + step;
}

__attribute__((naked, aligned(4)))
void trap_handler(void) {
    __asm__ volatile(
        "addi sp, sp, -32\n"
        "sw   ra, 0(sp)\n"
        "sw   a0, 4(sp)\n"
        "sw   a1, 8(sp)\n"
        "sw   a2, 12(sp)\n"
        "csrr a0, mcause\n"
        "csrr a1, mepc\n"
        "addi a2, sp, 16\n"
        "call trap_dispatch\n"
        "lw   a2, 16(sp)\n"
        "csrw mepc, a2\n"
        "lw   ra, 0(sp)\n"
        "lw   a0, 4(sp)\n"
        "lw   a1, 8(sp)\n"
        "lw   a2, 12(sp)\n"
        "addi sp, sp, 32\n"
        "mret\n"
    );
}
