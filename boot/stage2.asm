bits 16

global s2_start

extern a20_enable
extern print
extern clear_screen

;------------------------------------------------------------------------------
; Data Section
;------------------------------------------------------------------------------
STACK_TOP equ 0x90000                ; Top of stack 0x90000 (576kb)
STACK_BOTTOM equ 0x80000             ; Bottom of stack 64kb of stack.(not used just for rem)

msg             db "Zeen OS", 0x0D, 0x0A, 0
boot_message    db "Load...", 0x0D, 0x0A, 0
loading_success db "OK!", 0x0D, 0x0A, 0
loading_error db "Disk read error!", 0x0D,0x0A,0
a20_fail_msg db "Fail to activate A20 line exiting...", 0xD, 0xA, 0x0

jmp s2_start

s2_start:
    call clear_screen
    mov si, msg
    call print
    mov si, boot_message
    call print

    call a20_enable
    cmp ax, 1
    je a20_fail 

    ; setup gdt
    

a20_fail:
    push si
    mov si, a20_fail_msg
    call print
    jmp $

