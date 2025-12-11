bits 16

global s2_start
jmp s2_start

extern a20_enable
extern print
extern clear_screen

;------------------------------------------------------------------------------
; Data Section
;------------------------------------------------------------------------------
STACK_TOP equ 0x90000                ; Top of stack 0x90000 (576kb)
STACK_BOTTOM equ 0x80000             ; Bottom of stack 64kb of stack.(not used just for rem)

s2_message db "Starting stage 2...", 0x0D, 0xA, 0x0
a20_fail_msg db "Fail to activate A20 line, exiting...", 0xD, 0xA, 0x0
a20_success_msg db "Activated A20...", 0xD, 0xA, 0x0

s2_start:
    call clear_screen
    mov si, s2_message
    call print

    call a20_enable
    cmp ax, 1
    ; jne a20_fail 
    je a20_fail

    ; setup gdt
    

a20_fail:
    push si
    mov si, a20_fail_msg
    call print
    jmp $

