MEMORY {
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 128M
}

SECTIONS {
    . = 0x80000000;
    .text : { *(.text.start) *(.text*) } > RAM
    .data : { *(.data*) } > RAM
    .bss  : { *(.bss*) } > RAM
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
