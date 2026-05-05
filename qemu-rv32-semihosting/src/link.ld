/* Linker script for QEMU `virt` machine (RISC-V32, bare-metal).
 *
 * QEMU loads the ELF and jumps to the entry point at 0x80000000. With
 * `-bios none` we run in M-mode from reset; the device tree is in a1
 * (ignored here).
 */

OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 128M
}

SECTIONS
{
    .text : {
        KEEP(*(.text.init))
        *(.text .text.*)
    } > RAM

    .rodata : {
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
    } > RAM

    .preinit_array : {
        PROVIDE_HIDDEN(__preinit_array_start = .);
        KEEP(*(.preinit_array))
        PROVIDE_HIDDEN(__preinit_array_end = .);
    } > RAM

    .init_array : {
        PROVIDE_HIDDEN(__init_array_start = .);
        KEEP(*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
        KEEP(*(EXCLUDE_FILE(*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o) .init_array .ctors))
        PROVIDE_HIDDEN(__init_array_end = .);
    } > RAM

    .fini_array : {
        PROVIDE_HIDDEN(__fini_array_start = .);
        KEEP(*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
        KEEP(*(EXCLUDE_FILE(*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o) .fini_array .dtors))
        PROVIDE_HIDDEN(__fini_array_end = .);
    } > RAM

    .data : {
        *(.data .data.*)
        *(.sdata .sdata.*)
    } > RAM

    .bss (NOLOAD) : {
        _bss_start = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
        _end = .; /* Symbol expected by newlib's allocator */
    } > RAM

    /* Stack placed at top of RAM */
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);

    /DISCARD/ : { *(.eh_frame) *(.note.*) *(.comment) }
}
