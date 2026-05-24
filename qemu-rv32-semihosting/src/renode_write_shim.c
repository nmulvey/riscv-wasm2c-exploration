/*
 * _write shim for running ARM Cortex-M ELFs under Renode.
 *
 * Why this file exists:
 *   Renode's ARM semihosting handler (Arm.cs / DoSemihosting) implements only
 *   three operations: 0x03 SYS_WRITEC, 0x04 SYS_WRITE0, and 0x07 SYS_READC.
 *   Newlib's librdimon does fd-based stdio: at startup it issues 0x01 SYS_OPEN
 *   to get host handles for stdin/stdout/stderr, and every printf() ultimately
 *   calls _write -> 0x05 SYS_WRITE against those handles. Neither SYS_OPEN nor
 *   SYS_WRITE is implemented in Renode, so under stock librdimon all printf()
 *   output is silently dropped — the program runs, but nothing reaches the
 *   terminal. QEMU implements the full semihosting spec and is unaffected.
 *
 * What this file does:
 *   Provides a strong _write definition. Because it comes before -lrdimon on
 *   the link line (libraries are searched only for unresolved symbols), the
 *   linker takes this one instead of librdimon's _write.o. Every byte of every
 *   write() call is emitted via SYS_WRITEC (op 0x03) — which both QEMU and
 *   Renode handle — using a `bkpt 0xab` Thumb trap.
 *
 * Cost on QEMU:
 *   One semihosting trap per byte instead of one per buffer. printf() is not
 *   in the BENCH timing window in any of our entrypoints, so this doesn't
 *   skew benchmark numbers. If that ever changes, swap to a SYS_WRITE0
 *   batched-string variant.
 *
 * Scope:
 *   Wired into the ARM family block of the Makefile via EXTRA_COMMON_OBJS.
 *   Not linked into RISC-V builds (those go through libgloss-riscv, which
 *   uses different syscalls and isn't affected by Renode's coverage gap).
 */

#include <stdint.h>

static inline void sys_writec(char c) {
    register uint32_t op __asm__("r0") = 0x03;
    register const void* p __asm__("r1") = &c;
    __asm__ volatile("bkpt 0xab" : "+r"(op), "+r"(p) : : "memory");
}

int _write(int fd, const char* buf, int len) {
    (void)fd;
    for (int i = 0; i < len; i++) {
        sys_writec(buf[i]);
    }
    return len;
}
