	.text
	.attribute	4, 16
	.attribute	5, "rv32i2p1_m2p0_a2p1_c2p0_zmmul1p0"
	.file	"align_probe_defensive.c"
	.globl	load_i32_defensive              # -- Begin function load_i32_defensive
	.p2align	1
	.type	load_i32_defensive,@function
load_i32_defensive:                     # @load_i32_defensive
# %bb.0:
	lui	a1, %hi(sandbox_mem)
	addi	a1, a1, %lo(sandbox_mem)
	add	a0, a0, a1
	lw	a0, 0(a0)
	ret
.Lfunc_end0:
	.size	load_i32_defensive, .Lfunc_end0-load_i32_defensive
                                        # -- End function
	.globl	load_i32_optimized              # -- Begin function load_i32_optimized
	.p2align	1
	.type	load_i32_optimized,@function
load_i32_optimized:                     # @load_i32_optimized
# %bb.0:
	lui	a1, %hi(sandbox_mem)
	addi	a1, a1, %lo(sandbox_mem)
	add	a0, a0, a1
	lw	a0, 0(a0)
	ret
.Lfunc_end1:
	.size	load_i32_optimized, .Lfunc_end1-load_i32_optimized
                                        # -- End function
	.globl	main                            # -- Begin function main
	.p2align	1
	.type	main,@function
main:                                   # @main
# %bb.0:
	addi	sp, sp, -16
	sw	ra, 12(sp)                      # 4-byte Folded Spill
	sw	s0, 8(sp)                       # 4-byte Folded Spill
	sw	s1, 4(sp)                       # 4-byte Folded Spill
	sw	s2, 0(sp)                       # 4-byte Folded Spill
	lui	a0, %hi(.L.str)
	addi	a0, a0, %lo(.L.str)
	call	semi_puts
	lui	a0, %hi(.L.str.1)
	addi	a0, a0, %lo(.L.str.1)
	call	semi_puts
	li	a0, 0
	call	load_i32_defensive
	call	semi_puthex
	lui	s0, %hi(.L.str.2)
	addi	s0, s0, %lo(.L.str.2)
	mv	a0, s0
	call	semi_puts
	lui	a0, %hi(.L.str.3)
	addi	a0, a0, %lo(.L.str.3)
	call	semi_puts
	li	a0, 0
	call	load_i32_optimized
	call	semi_puthex
	mv	a0, s0
	call	semi_puts
	lui	s2, %hi(.L.str.4)
	addi	s2, s2, %lo(.L.str.4)
	mv	a0, s2
	call	semi_puts
	li	a0, 1
	call	semi_puthex
	lui	s1, %hi(.L.str.5)
	addi	s1, s1, %lo(.L.str.5)
	mv	a0, s1
	call	semi_puts
	li	a0, 1
	call	load_i32_defensive
	call	semi_puthex
	lui	s0, %hi(.L.str.6)
	addi	s0, s0, %lo(.L.str.6)
	mv	a0, s0
	call	semi_puts
	mv	a0, s2
	call	semi_puts
	li	a0, 2
	call	semi_puthex
	mv	a0, s1
	call	semi_puts
	li	a0, 2
	call	load_i32_defensive
	call	semi_puthex
	mv	a0, s0
	call	semi_puts
	mv	a0, s2
	call	semi_puts
	li	a0, 3
	call	semi_puthex
	mv	a0, s1
	call	semi_puts
	li	a0, 3
	call	load_i32_defensive
	call	semi_puthex
	mv	a0, s0
	call	semi_puts
	lui	a0, %hi(.L.str.7)
	addi	a0, a0, %lo(.L.str.7)
	call	semi_puts
	li	a0, 0
	lw	ra, 12(sp)                      # 4-byte Folded Reload
	lw	s0, 8(sp)                       # 4-byte Folded Reload
	lw	s1, 4(sp)                       # 4-byte Folded Reload
	lw	s2, 0(sp)                       # 4-byte Folded Reload
	addi	sp, sp, 16
	ret
.Lfunc_end2:
	.size	main, .Lfunc_end2-main
                                        # -- End function
	.type	.L.str,@object                  # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"== alignment probe start ==\n"
	.size	.L.str, 29

	.type	.L.str.1,@object                # @.str.1
.L.str.1:
	.asciz	"aligned defensive addr=0: "
	.size	.L.str.1, 27

	.type	.L.str.2,@object                # @.str.2
.L.str.2:
	.asciz	"\n"
	.size	.L.str.2, 2

	.type	.L.str.3,@object                # @.str.3
.L.str.3:
	.asciz	"aligned optimized addr=0: "
	.size	.L.str.3, 27

	.type	.L.str.4,@object                # @.str.4
.L.str.4:
	.asciz	"misaligned defensive addr="
	.size	.L.str.4, 27

	.type	.L.str.5,@object                # @.str.5
.L.str.5:
	.asciz	": "
	.size	.L.str.5, 3

	.type	.L.str.6,@object                # @.str.6
.L.str.6:
	.asciz	"  (survived)\n"
	.size	.L.str.6, 14

	.type	.L.str.7,@object                # @.str.7
.L.str.7:
	.asciz	"== all misaligned loads completed, no trap ==\n"
	.size	.L.str.7, 47

	.type	sandbox_mem,@object             # @sandbox_mem
	.data
	.p2align	4, 0x0
sandbox_mem:
	.ascii	"\000\021\"3DUfw\210\231\252\273\314\335\356\377"
	.zero	240
	.size	sandbox_mem, 256

	.ident	"Debian clang version 19.1.7 (3+b1)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym sandbox_mem
