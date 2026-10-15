	.file	"align_probe_defensive.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_c2p0_zicsr2p0_zifencei2p0"
	.attribute unaligned_access, 1
	.attribute stack_align, 16
	.text
	.align	1
	.globl	load_i32_defensive
	.type	load_i32_defensive, @function
load_i32_defensive:
	lui	a5,%hi(.LANCHOR0)
	addi	a5,a5,%lo(.LANCHOR0)
	add	a0,a5,a0
	lbu	a1,0(a0)
	lbu	a2,1(a0)
	lbu	a3,2(a0)
	lbu	a4,3(a0)
	addi	sp,sp,-16
	sb	a1,12(sp)
	sb	a2,13(sp)
	sb	a3,14(sp)
	sb	a4,15(sp)
	lw	a0,12(sp)
	addi	sp,sp,16
	jr	ra
	.size	load_i32_defensive, .-load_i32_defensive
	.align	1
	.globl	load_i32_optimized
	.type	load_i32_optimized, @function
load_i32_optimized:
	lui	a5,%hi(.LANCHOR0)
	addi	a5,a5,%lo(.LANCHOR0)
	add	a5,a5,a0
	lw	a0,0(a5)
	ret
	.size	load_i32_optimized, .-load_i32_optimized
	.section	.rodata.str1.4,"aMS",@progbits,1
	.align	2
.LC0:
	.string	"== alignment probe start ==\n"
	.align	2
.LC1:
	.string	"aligned defensive addr=0: "
	.align	2
.LC2:
	.string	"\n"
	.align	2
.LC3:
	.string	"aligned optimized addr=0: "
	.align	2
.LC4:
	.string	"misaligned defensive addr="
	.align	2
.LC5:
	.string	": "
	.align	2
.LC6:
	.string	"  (survived)\n"
	.align	2
.LC7:
	.string	"== all misaligned loads completed, no trap ==\n"
	.section	.text.startup,"ax",@progbits
	.align	1
	.globl	main
	.type	main, @function
main:
	lui	a0,%hi(.LC0)
	addi	sp,sp,-32
	addi	a0,a0,%lo(.LC0)
	sw	ra,28(sp)
	sw	s0,24(sp)
	sw	s1,20(sp)
	sw	s2,16(sp)
	sw	s3,12(sp)
	sw	s4,8(sp)
	call	semi_puts
	lui	a0,%hi(.LC1)
	addi	a0,a0,%lo(.LC1)
	call	semi_puts
	li	a0,0
	call	load_i32_defensive
	lui	s0,%hi(.LC2)
	call	semi_puthex
	addi	a0,s0,%lo(.LC2)
	call	semi_puts
	lui	a0,%hi(.LC3)
	addi	a0,a0,%lo(.LC3)
	call	semi_puts
	li	a0,0
	call	load_i32_optimized
	call	semi_puthex
	addi	a0,s0,%lo(.LC2)
	call	semi_puts
	li	s0,1
	lui	s4,%hi(.LC4)
	lui	s3,%hi(.LC5)
	lui	s2,%hi(.LC6)
	li	s1,4
.L6:
	addi	a0,s4,%lo(.LC4)
	call	semi_puts
	mv	a0,s0
	call	semi_puthex
	addi	a0,s3,%lo(.LC5)
	call	semi_puts
	mv	a0,s0
	call	load_i32_defensive
	call	semi_puthex
	addi	a0,s2,%lo(.LC6)
	addi	s0,s0,1
	call	semi_puts
	bne	s0,s1,.L6
	lui	a0,%hi(.LC7)
	addi	a0,a0,%lo(.LC7)
	call	semi_puts
	lw	ra,28(sp)
	lw	s0,24(sp)
	lw	s1,20(sp)
	lw	s2,16(sp)
	lw	s3,12(sp)
	lw	s4,8(sp)
	li	a0,0
	addi	sp,sp,32
	jr	ra
	.size	main, .-main
	.data
	.align	4
	.set	.LANCHOR0,. + 0
	.type	sandbox_mem, @object
	.size	sandbox_mem, 256
sandbox_mem:
	.string	""
	.string	"\021\"3DUfw\210\231\252\273\314\335\356\377"
	.zero	239
	.ident	"GCC: (14.2.0+19) 14.2.0"
	.section	.note.GNU-stack,"",@progbits
