/* Bare-metal entry for ARMv7-M and later (Cortex-M3/M4/M7, ARMv8-M.main).
 *
 * Not suitable for ARMv6-M (Cortex-M0/M0+): the copy/zero loops use the
 * Thumb-2-only post-indexed `ldr/str Rt, [Rn], #imm` encoding. A v6-M
 * port would split each into a separate load/store + `adds`.
 *
 * Layout differences from src/crt0.S (RISC-V):
 *   - Cortex-M reads the initial SP from vector_table[0] in hardware at
 *     reset, so we don't set sp ourselves; we just place the value in
 *     .isr_vector.
 *   - Reset_Handler must copy .data from its LMA (in FLASH) to its VMA
 *     (in SRAM); the linker script provides _sidata/_sdata/_edata.
 *   - On parts with an FPU (Cortex-M4F, M7, M33+, …) the FPU is disabled
 *     out of reset. We enable CP10/CP11 in CPACR before any FP code
 *     runs (compilers may spill FP regs in the prologue of any function
 *     compiled with -mfloat-abi=hard).
 *
 * Vector table is intentionally minimal: NMI/HardFault/etc. spin in
 * Default_Handler. We don't wire any external interrupts because the
 * test programs don't enable any.
 */

    .syntax unified
    .thumb

/* ----------------------------------------------------------------------- */
/* Vector table                                                             */
/* ----------------------------------------------------------------------- */

    .section .isr_vector, "a", %progbits
    .align  2
    .global vector_table
    .type   vector_table, %object
vector_table:
    .word   _stack_top              /* 0:  Initial SP                     */
    .word   Reset_Handler           /* 1:  Reset                          */
    .word   Default_Handler         /* 2:  NMI                            */
    .word   Default_Handler         /* 3:  HardFault                      */
    .word   Default_Handler         /* 4:  MemManage                      */
    .word   Default_Handler         /* 5:  BusFault                       */
    .word   Default_Handler         /* 6:  UsageFault                     */
    .word   0                       /* 7:  reserved                       */
    .word   0                       /* 8:  reserved                       */
    .word   0                       /* 9:  reserved                       */
    .word   0                       /* 10: reserved                       */
    .word   Default_Handler         /* 11: SVCall                         */
    .word   Default_Handler         /* 12: Debug Monitor                  */
    .word   0                       /* 13: reserved                       */
    .word   Default_Handler         /* 14: PendSV                         */
    .word   Default_Handler         /* 15: SysTick                        */
    /* External interrupts (16..) intentionally omitted. */
    .size   vector_table, . - vector_table

/* ----------------------------------------------------------------------- */
/* Reset handler                                                            */
/* ----------------------------------------------------------------------- */

    .section .text.Reset_Handler, "ax", %progbits
    .align  2
    .thumb_func
    .global Reset_Handler
    .type   Reset_Handler, %function
Reset_Handler:
    /* Enable FPU (CP10 + CP11, full access) if the build targets hard-
     * or softfp ABI. CPACR is at 0xE000ED88. On parts without an FPU
     * (e.g. Cortex-M3) this region is RAZ/WI, so the writes are safe
     * to perform unconditionally. We gate the actual write on the
     * compiler's __ARM_FP macro to avoid pointlessly touching the
     * register on -mfloat-abi=soft builds. */
#if defined(__ARM_FP)
    ldr     r0, =0xE000ED88
    ldr     r1, [r0]
    orr     r1, r1, #(0xF << 20)
    str     r1, [r0]
    dsb
    isb
#endif

    /* Copy .data from FLASH (LMA = _sidata) into SRAM (VMA = _sdata..). */
    ldr     r0, =_sidata
    ldr     r1, =_sdata
    ldr     r2, =_edata
1:  cmp     r1, r2
    bhs     2f
    ldr     r3, [r0], #4
    str     r3, [r1], #4
    b       1b
2:

    /* Zero .bss. */
    ldr     r0, =_bss_start
    ldr     r1, =_bss_end
    movs    r2, #0
3:  cmp     r0, r1
    bhs     4f
    str     r2, [r0], #4
    b       3b
4:

    /* Open stdin/stdout/stderr through semihosting. ARM librdimon (unlike
     * the RISC-V libsemihost) doesn't have fixed handles for the standard
     * streams: each `printf` ultimately calls SYS_WRITE with a handle that
     * must come from a prior SYS_OPEN(":tt", …). The librdimon source ships
     * a helper `initialise_monitor_handles` that issues the three opens and
     * fills its internal fd→handle table; with -specs=rdimon.specs the
     * vendor `rdimon-crt0.o` would call it for us, but we use -nostartfiles
     * (we own the vector table and the memory map), so we invoke it here.
     * Without this call, _write succeeds at the SWI level but with
     * handle=0, which QEMU silently no-ops — printf produces no output.
     */
    bl      initialise_monitor_handles

    /* C++/C constructors registered in .init_array. */
    bl      __libc_init_array

    /* main(0, NULL). */
    movs    r0, #0
    movs    r1, #0
    bl      main

    /* exit(rc). With -specs=rdimon.specs (or explicit -lrdimon), newlib's
     * librdimon implements _exit via the semihosting SYS_EXIT call, which
     * terminates QEMU with the given status. */
    bl      exit

    /* Unreachable. */
5:  b       5b
    .size   Reset_Handler, . - Reset_Handler

/* ----------------------------------------------------------------------- */
/* Default handler for unused vectors                                       */
/* ----------------------------------------------------------------------- */

    .section .text.Default_Handler, "ax", %progbits
    .align  2
    .thumb_func
    .global Default_Handler
    .type   Default_Handler, %function
Default_Handler:
6:  b       6b
    .size   Default_Handler, . - Default_Handler

/* ----------------------------------------------------------------------- */
/* Empty _init / _fini                                                      */
/*                                                                          */
/* gcc-arm-embedded's newlib __libc_init_array / __libc_fini_array call    */
/* into platform-supplied _init / _fini. These normally come from          */
/* crti.o / crtn.o, but `-nostartfiles` excludes them. Our test programs   */
/* don't ship any pre-main hand-rolled init code, so a pair of trivial    */
/* leaf functions is enough. */
/* ----------------------------------------------------------------------- */

    /* `.weak` implies global binding, so no separate `.global` directive —
     * clang's integrated assembler warns about redeclaring the binding if
     * both are present. (GNU as is more permissive about that pattern.) */
    .section .text._init, "ax", %progbits
    .align  2
    .thumb_func
    .weak   _init
    .type   _init, %function
_init:
    bx      lr
    .size   _init, . - _init

    .section .text._fini, "ax", %progbits
    .align  2
    .thumb_func
    .weak   _fini
    .type   _fini, %function
_fini:
    bx      lr
    .size   _fini, . - _fini
