ENTRY(gdt_init)

PHDRS
{
    text PT_LOAD FLAGS(0x05)
    data PT_LOAD FLAGS(0x06)
    bss PT_LOAD FLAGS(0x06)
}


SECTIONS
{
    . = 0x
}
