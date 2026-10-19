	.file	"guest_w2c.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_c2p0_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	1
	.globl	w2c_0x24guest0x2Ewasm_memory
	.type	w2c_0x24guest0x2Ewasm_memory, @function
w2c_0x24guest0x2Ewasm_memory:
	addi	a0,a0,40
	ret
	.size	w2c_0x24guest0x2Ewasm_memory, .-w2c_0x24guest0x2Ewasm_memory
	.align	1
	.globl	w2c_0x24guest0x2Ewasm_0x5F_wasm_call_ctors
	.type	w2c_0x24guest0x2Ewasm_0x5F_wasm_call_ctors, @function
w2c_0x24guest0x2Ewasm_0x5F_wasm_call_ctors:
	lui	a5,%tprel_hi(wasm_rt_call_stack_depth)
	add	a5,a5,tp,%tprel_add(wasm_rt_call_stack_depth)
	lw	a4,%tprel_lo(wasm_rt_call_stack_depth)(a5)
	li	a2,500
	addi	a3,a4,1
	sw	a3,%tprel_lo(wasm_rt_call_stack_depth)(a5)
	bgtu	a3,a2,.L8
	sw	a4,%tprel_lo(wasm_rt_call_stack_depth)(a5)
	ret
.L8:
	addi	sp,sp,-16
	li	a0,9
	sw	ra,12(sp)
	call	wasm_rt_trap
	.size	w2c_0x24guest0x2Ewasm_0x5F_wasm_call_ctors, .-w2c_0x24guest0x2Ewasm_0x5F_wasm_call_ctors
	.align	1
	.globl	w2c_0x24guest0x2Ewasm_load_u32_ptr
	.type	w2c_0x24guest0x2Ewasm_load_u32_ptr, @function
w2c_0x24guest0x2Ewasm_load_u32_ptr:
	lui	a4,%tprel_hi(wasm_rt_call_stack_depth)
	add	a3,a4,tp,%tprel_add(wasm_rt_call_stack_depth)
	lw	a2,%tprel_lo(wasm_rt_call_stack_depth)(a3)
	addi	sp,sp,-32
	sw	ra,28(sp)
	addi	a5,a2,1
	sw	a5,%tprel_lo(wasm_rt_call_stack_depth)(a3)
	li	a3,500
	bgtu	a5,a3,.L15
	lw	a3,68(a0)
	addi	a6,a1,4
	sltu	a5,a6,a1
	bltu	a3,a5,.L13
	beq	a3,a5,.L16
.L11:
	lw	a5,40(a0)
	add	a1,a5,a1
	lbu	a0,2(a1)
	lbu	a7,0(a1)
	lbu	a6,1(a1)
	lbu	a5,3(a1)
	sb	a7,12(sp)
	sb	a6,13(sp)
	sb	a0,14(sp)
	sb	a5,15(sp)
	lw	a0,12(sp)
	lw	ra,28(sp)
	add	a4,a4,tp,%tprel_add(wasm_rt_call_stack_depth)
	sw	a2,%tprel_lo(wasm_rt_call_stack_depth)(a4)
	addi	sp,sp,32
	jr	ra
.L16:
	lw	a5,64(a0)
	bgeu	a5,a6,.L11
.L13:
	li	a0,1
	call	wasm_rt_trap
.L15:
	li	a0,9
	call	wasm_rt_trap
	.size	w2c_0x24guest0x2Ewasm_load_u32_ptr, .-w2c_0x24guest0x2Ewasm_load_u32_ptr
	.align	1
	.globl	w2c_0x24guest0x2Ewasm_load_u32_bytes
	.type	w2c_0x24guest0x2Ewasm_load_u32_bytes, @function
w2c_0x24guest0x2Ewasm_load_u32_bytes:
	lui	a4,%tprel_hi(wasm_rt_call_stack_depth)
	add	a3,a4,tp,%tprel_add(wasm_rt_call_stack_depth)
	lw	a2,%tprel_lo(wasm_rt_call_stack_depth)(a3)
	addi	sp,sp,-32
	sw	ra,28(sp)
	addi	a5,a2,1
	sw	a5,%tprel_lo(wasm_rt_call_stack_depth)(a3)
	li	a3,500
	bgtu	a5,a3,.L23
	lw	a3,68(a0)
	addi	a6,a1,4
	sltu	a5,a6,a1
	bltu	a3,a5,.L21
	beq	a3,a5,.L24
.L19:
	lw	a5,40(a0)
	add	a1,a5,a1
	lbu	a0,2(a1)
	lbu	a7,0(a1)
	lbu	a6,1(a1)
	lbu	a5,3(a1)
	sb	a7,12(sp)
	sb	a6,13(sp)
	sb	a0,14(sp)
	sb	a5,15(sp)
	lw	a0,12(sp)
	lw	ra,28(sp)
	add	a4,a4,tp,%tprel_add(wasm_rt_call_stack_depth)
	sw	a2,%tprel_lo(wasm_rt_call_stack_depth)(a4)
	addi	sp,sp,32
	jr	ra
.L24:
	lw	a5,64(a0)
	bgeu	a5,a6,.L19
.L21:
	li	a0,1
	call	wasm_rt_trap
.L23:
	li	a0,9
	call	wasm_rt_trap
	.size	w2c_0x24guest0x2Ewasm_load_u32_bytes, .-w2c_0x24guest0x2Ewasm_load_u32_bytes
	.align	1
	.globl	w2c_0x24guest0x2Ewasm_0x5F_dso_handle
	.type	w2c_0x24guest0x2Ewasm_0x5F_dso_handle, @function
w2c_0x24guest0x2Ewasm_0x5F_dso_handle:
	addi	a0,a0,4
	ret
	.size	w2c_0x24guest0x2Ewasm_0x5F_dso_handle, .-w2c_0x24guest0x2Ewasm_0x5F_dso_handle
	.align	1
	.globl	w2c_0x24guest0x2Ewasm_0x5F_data_end
	.type	w2c_0x24guest0x2Ewasm_0x5F_data_end, @function
w2c_0x24guest0x2Ewasm_0x5F_data_end:
	addi	a0,a0,8
	ret
	.size	w2c_0x24guest0x2Ewasm_0x5F_data_end, .-w2c_0x24guest0x2Ewasm_0x5F_data_end
	.align	1
	.globl	w2c_0x24guest0x2Ewasm_0x5F_stack_low
	.type	w2c_0x24guest0x2Ewasm_0x5F_stack_low, @function
w2c_0x24guest0x2Ewasm_0x5F_stack_low:
	addi	a0,a0,12
	ret
	.size	w2c_0x24guest0x2Ewasm_0x5F_stack_low, .-w2c_0x24guest0x2Ewasm_0x5F_stack_low
	.align	1
	.globl	w2c_0x24guest0x2Ewasm_0x5F_stack_high
	.type	w2c_0x24guest0x2Ewasm_0x5F_stack_high, @function
w2c_0x24guest0x2Ewasm_0x5F_stack_high:
	addi	a0,a0,16
	ret
	.size	w2c_0x24guest0x2Ewasm_0x5F_stack_high, .-w2c_0x24guest0x2Ewasm_0x5F_stack_high
	.align	1
	.globl	w2c_0x24guest0x2Ewasm_0x5F_global_base
	.type	w2c_0x24guest0x2Ewasm_0x5F_global_base, @function
w2c_0x24guest0x2Ewasm_0x5F_global_base:
	addi	a0,a0,20
	ret
	.size	w2c_0x24guest0x2Ewasm_0x5F_global_base, .-w2c_0x24guest0x2Ewasm_0x5F_global_base
	.align	1
	.globl	w2c_0x24guest0x2Ewasm_0x5F_heap_base
	.type	w2c_0x24guest0x2Ewasm_0x5F_heap_base, @function
w2c_0x24guest0x2Ewasm_0x5F_heap_base:
	addi	a0,a0,24
	ret
	.size	w2c_0x24guest0x2Ewasm_0x5F_heap_base, .-w2c_0x24guest0x2Ewasm_0x5F_heap_base
	.align	1
	.globl	w2c_0x24guest0x2Ewasm_0x5F_heap_end
	.type	w2c_0x24guest0x2Ewasm_0x5F_heap_end, @function
w2c_0x24guest0x2Ewasm_0x5F_heap_end:
	addi	a0,a0,28
	ret
	.size	w2c_0x24guest0x2Ewasm_0x5F_heap_end, .-w2c_0x24guest0x2Ewasm_0x5F_heap_end
	.align	1
	.globl	w2c_0x24guest0x2Ewasm_0x5F_memory_base
	.type	w2c_0x24guest0x2Ewasm_0x5F_memory_base, @function
w2c_0x24guest0x2Ewasm_0x5F_memory_base:
	addi	a0,a0,32
	ret
	.size	w2c_0x24guest0x2Ewasm_0x5F_memory_base, .-w2c_0x24guest0x2Ewasm_0x5F_memory_base
	.align	1
	.globl	w2c_0x24guest0x2Ewasm_0x5F_table_base
	.type	w2c_0x24guest0x2Ewasm_0x5F_table_base, @function
w2c_0x24guest0x2Ewasm_0x5F_table_base:
	addi	a0,a0,36
	ret
	.size	w2c_0x24guest0x2Ewasm_0x5F_table_base, .-w2c_0x24guest0x2Ewasm_0x5F_table_base
	.section	.rodata.str1.4,"aMS",@progbits,1
	.align	2
.LC0:
	.string	"wasm_rt_is_initialized()"
	.align	2
.LC1:
	.string	"guest_w2c.c"
	.text
	.align	1
	.globl	wasm2c_0x24guest0x2Ewasm_instantiate
	.type	wasm2c_0x24guest0x2Ewasm_instantiate, @function
wasm2c_0x24guest0x2Ewasm_instantiate:
	addi	sp,sp,-16
	sw	s0,8(sp)
	sw	ra,12(sp)
	mv	s0,a0
	call	wasm_rt_is_initialized
	beq	a0,zero,.L37
	li	a5,65536
	li	a4,1024
	addi	a5,a5,1024
	li	a2,131072
	li	a3,1
	sw	a5,0(s0)
	sw	a5,16(s0)
	sw	a5,24(s0)
	sw	a4,4(s0)
	sw	a4,8(s0)
	sw	a4,12(s0)
	sw	a4,20(s0)
	sw	a2,28(s0)
	sw	a3,36(s0)
	sw	zero,32(s0)
	addi	a0,s0,40
	lw	s0,8(sp)
	lw	ra,12(sp)
	li	a5,0
	li	a3,65536
	li	a4,0
	li	a1,2
	li	a2,0
	addi	sp,sp,16
	tail	wasm_rt_allocate_memory
.L37:
	lui	a2,%hi(.LANCHOR0)
	lui	a3,%hi(.LC0)
	lui	a0,%hi(.LC1)
	addi	a2,a2,%lo(.LANCHOR0)
	addi	a3,a3,%lo(.LC0)
	addi	a0,a0,%lo(.LC1)
	li	a1,815
	call	__assert_func
	.size	wasm2c_0x24guest0x2Ewasm_instantiate, .-wasm2c_0x24guest0x2Ewasm_instantiate
	.align	1
	.globl	wasm2c_0x24guest0x2Ewasm_free
	.type	wasm2c_0x24guest0x2Ewasm_free, @function
wasm2c_0x24guest0x2Ewasm_free:
	addi	a0,a0,40
	tail	wasm_rt_free_memory
	.size	wasm2c_0x24guest0x2Ewasm_free, .-wasm2c_0x24guest0x2Ewasm_free
	.section	.rodata.str1.4
	.align	2
.LC2:
	.string	"6\251\347\361\311[\202\377\271\227C\340\305\304\316\225\330<\232C\n\254Y\370N\363\313\372\266\024Ph"
	.text
	.align	1
	.globl	wasm2c_0x24guest0x2Ewasm_get_func_type
	.type	wasm2c_0x24guest0x2Ewasm_get_func_type, @function
wasm2c_0x24guest0x2Ewasm_get_func_type:
	addi	sp,sp,-48
	sw	a5,36(sp)
	sw	a2,24(sp)
	sw	a3,28(sp)
	sw	a4,32(sp)
	sw	a6,40(sp)
	sw	a7,44(sp)
	or	a5,a0,a1
	beq	a5,zero,.L45
	li	a5,1
	bne	a0,a5,.L42
	beq	a1,a0,.L43
.L42:
	li	a0,0
.L39:
	addi	sp,sp,48
	jr	ra
.L45:
	addi	a5,sp,24
	sw	a5,12(sp)
	lui	a0,%hi(.LC2)
	addi	a0,a0,%lo(.LC2)
	addi	sp,sp,48
	jr	ra
.L43:
	addi	a5,sp,24
	sw	a5,12(sp)
	bne	a2,zero,.L42
	lw	a5,28(sp)
	bne	a5,zero,.L42
	lui	a0,%hi(.LANCHOR0+40)
	addi	a0,a0,%lo(.LANCHOR0+40)
	j	.L39
	.size	wasm2c_0x24guest0x2Ewasm_get_func_type, .-wasm2c_0x24guest0x2Ewasm_get_func_type
	.section	.rodata
	.align	2
	.set	.LANCHOR0,. + 0
	.type	__func__.0, @object
	.size	__func__.0, 37
__func__.0:
	.string	"wasm2c_0x24guest0x2Ewasm_instantiate"
	.zero	3
.LC3:
	.string	"\007\200\226zB\367>\346p\\/\254\203\365g\322\242\240iA_\370\347\226\177#\253"
	.string	"\003_J<"
	.ident	"GCC: (14.2.0+19) 14.2.0"
	.section	.note.GNU-stack,"",@progbits
