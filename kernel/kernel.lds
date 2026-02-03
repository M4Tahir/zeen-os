ENTRY(_start)

PHDRS
{
    text PT_LOAD FLAGS(0x5); /* R-X */
    data PT_LOAD FLAGS(0x6); /* RW */
    bss  PT_LOAD FLAGS(0x6); /* RW */
}

SECTIONS
{
    . = 0x10000;

    .text : ALIGN(0x100){
        *(.text)
        *(.text.*)
        *(.rodata)
        *(.rodata.*)
    } :text

    .data : {
        *(.data)
        *(.data.*)
    } :data

    .bss : {
        *(.bss)
        *(COMMON)
    } :bss

    /DISCARD/ : {
        *(.eh_frame)
        *(.eh_frame.*)
        *(note)
        *(note.*)
    }
}
