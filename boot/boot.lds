
/* As the boot.asm file has label start:*/
ENTRY(start)

SECTIONS {
    . = 0x7C00;         /* The physical address where BIOS loads the boot sector */

    .text : {
        *(.text)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }
}

