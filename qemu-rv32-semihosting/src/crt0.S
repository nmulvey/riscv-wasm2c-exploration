/* Minimal bare-metal entry for QEMU `virt` (RISC-V32, M-mode). */

    .section .text.init, "ax"
    .global  _start
    .type    _start, @function

_start:
    /* Set up the stack (top of image, see link.ld). */
    la      sp, _stack_top

    /* Enable the FPU if the build targets F/D (compile-time gate so the
       csr write isn't emitted for soft-float multilibs that don't have
       FS bits). After reset mstatus.FS = Off (0), and any F/D
       instruction would trap to an illegal-instruction handler we don't
       provide — manifesting as a silent hang. mstatus.FS = Dirty (3)
       leaves the registers writable for the first user. */
#if defined(__riscv_flen) && __riscv_flen >= 32
    li      t0, (3 << 13)   /* mstatus.FS = Dirty */
    csrs    mstatus, t0
#endif

    /* Zero .bss. */
    la      t0, _bss_start
    la      t1, _bss_end
1:  bgeu    t0, t1, 2f
    sw      zero, 0(t0)
    addi    t0, t0, 4
    j       1b
2:

    /* Run C++/C constructors registered in .init_array. */
    call    __libc_init_array

    /* main(0, NULL); */
    li      a0, 0
    li      a1, 0
    call    main

    /* exit(rc). With -specs=semihost.specs, newlib's libsemihost
       implements _exit via the semihosting SYS_EXIT call, which
       terminates QEMU with the given status. */
    call    exit

    /* Unreachable. */
3:  j       3b

    .size   _start, . - _start
