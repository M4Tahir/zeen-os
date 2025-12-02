
/* 2nd stage boot loader */
ENTRY(s2_start)

SECTIONS {
    . = 0x7E00;

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

