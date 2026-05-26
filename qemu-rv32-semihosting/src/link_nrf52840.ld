/* Linker script for the Nordic nRF52840 (ARM Cortex-M4F), e.g. the
 * nRF52840-DK driven over its on-board SEGGER J-Link.
 *
 * Memory map (bare-metal, no SoftDevice):
 *   - 1 MB on-chip FLASH at 0x00000000. OpenOCD/J-Link programs ELF
 *     segments here according to their LMAs.
 *   - 256 KB on-chip SRAM at 0x20000000 is read/write data.
 *
 * This is the same Cortex-M4F CPU as QEMU's `mps2-an386`; only the memory
 * sizes differ (the AN386 has 4 MB of each). The crt0 (src/crt0_arm_v7m.S),
 * sections, and symbols are identical — see src/link_mps2_an386.ld for the
 * annotated section-by-section rationale.
 *
 * Reset vector (vector_table) must be the first thing in FLASH so the
 * Cortex-M core can read the initial SP from offset 0 and the reset handler
 * address from offset 4 at boot.
 */

OUTPUT_ARCH(arm)
OUTPUT_FORMAT(elf32-littlearm)
ENTRY(Reset_Handler)

MEMORY
{
    FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 1024K
    SRAM  (rwx) : ORIGIN = 0x20000000, LENGTH = 256K
}

SECTIONS
{
    .isr_vector : {
        KEEP(*(.isr_vector))
    } > FLASH

    .text : {
        *(.text .text.*)
        *(.glue_7) *(.glue_7t)
        *(.gnu.linkonce.t.*)
    } > FLASH

    .rodata : {
        *(.rodata .rodata.*)
        *(.gnu.linkonce.r.*)
    } > FLASH

    /* ARM exception unwinding tables — pulled in by libgcc even when -fno-
     * exceptions, so we have to give them a home in FLASH. */
    .ARM.extab : {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    } > FLASH

    .ARM.exidx : {
        __exidx_start = .;
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        __exidx_end = .;
    } > FLASH

    .preinit_array : {
        PROVIDE_HIDDEN(__preinit_array_start = .);
        KEEP(*(.preinit_array))
        PROVIDE_HIDDEN(__preinit_array_end = .);
    } > FLASH

    .init_array : {
        PROVIDE_HIDDEN(__init_array_start = .);
        KEEP(*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
        KEEP(*(EXCLUDE_FILE(*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o) .init_array .ctors))
        PROVIDE_HIDDEN(__init_array_end = .);
    } > FLASH

    .fini_array : {
        PROVIDE_HIDDEN(__fini_array_start = .);
        KEEP(*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
        KEEP(*(EXCLUDE_FILE(*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o) .fini_array .dtors))
        PROVIDE_HIDDEN(__fini_array_end = .);
    } > FLASH

    /* .data: LMA in FLASH so it ships with the image; VMA in SRAM so the
     * program reads/writes the runtime copy. Reset_Handler copies LMA→VMA. */
    .data : {
        . = ALIGN(4);
        _sdata = .;
        *(.data .data.*)
        *(.gnu.linkonce.d.*)
        . = ALIGN(4);
        _edata = .;
    } > SRAM AT > FLASH
    _sidata = LOADADDR(.data);

    .bss (NOLOAD) : {
        . = ALIGN(4);
        _bss_start = .;
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
        /* `end` (no underscore) is what librdimon's _sbrk references; the
         * underscored alias matches the RISC-V link.ld convention. */
        _end = .;
        PROVIDE(end = .);
    } > SRAM

    _stack_top = ORIGIN(SRAM) + LENGTH(SRAM);

    /DISCARD/ : { *(.note.*) *(.comment) }
}
