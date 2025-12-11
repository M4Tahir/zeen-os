
/* 2nd stage boot loader */
ENTRY(s2_start)

SECTIONS {
    . = 0x7E00; /* cs:ip: 0x7e0:0x0 = 0x7e00 */

    .text : {
        KEEP(*(.text))
    }

    .data : {
        KEEP(*(.data))
    }

    .bss : {
        *(.bss)
    }
}

