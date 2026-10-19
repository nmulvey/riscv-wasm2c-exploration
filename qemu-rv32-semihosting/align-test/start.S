    .section .text.init
    .globl _start
_start:
    la      sp, _stack_top

    la      t0, trap_entry
    csrw    mtvec, t0

    call    main

    li      a0, 0x18
    la      a1, .Lexit_block
    j       .Lsemihost_call

.Lexit_block:
    .word   0x20026
    .word   0

    .align 4
trap_entry:
    csrr    a0, mcause
    call    report_trap
1:  wfi
    j       1b

    .globl semi_call
semi_call:
.Lsemihost_call:
    .balign 4
    .option push
    .option norvc
    slli    x0, x0, 0x1f
    ebreak
    srai    x0, x0, 7
    .option pop
    ret

    .section .bss
    .align 4
    .space 4096
_stack_top:
