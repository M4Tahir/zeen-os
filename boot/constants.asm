; constants.inc — shared between real mode and protected mode

global KERNEL_SEG equ 0x1000
global KERNEL_OFF equ 0x0000                ; Load kernal at addrss 64kb (0x1000*16+0x00 = 0x10000)
global KERNEL_SECT equ 32                   ; read 32 secotors
global KERNEL_LBA equ 2                     ; starting sector

global STACK_TOP equ 0x90000                ; Top of stack 0x90000 (576kb)
global STACK_BOTTOM equ 0x80000             ; Bottom of stack 64kb of stack.(not used just for rem)

