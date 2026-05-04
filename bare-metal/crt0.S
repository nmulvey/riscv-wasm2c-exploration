.section .text.start
.global _start
_start:
    # initialize UART
    li t0, 0x10000000
    li t1, 0x03        # LCR: 8N1
    sb t1, 3(t0)
    li t1, 0x01        # FCR: enable FIFO
    sb t1, 2(t0)
    li t1, 0x0B        # MCR: RTS+DTR+OUT2
    sb t1, 4(t0)

    la sp, _stack_top
    call main
1:  j 1b
