MEMORY {
    FLASH : ORIGIN = 0x80000000, LENGTH = 256K
    RAM   : ORIGIN = 0x80040000, LENGTH = 256K
}
SECTIONS {
    .text : { *(.text*) } > FLASH
    .data : { *(.data*) } > RAM
    .bss  : { *(.bss*)  } > RAM
}
