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
a20_success_msg db "Activated A20 line...", 0xD, 0xA, 0x0

s2_start:

    call clear_screen
    mov si, s2_message
    call print

    ; return ax = 1 (a20 success) ax = 0 ( a20 fail)
    call a20_enable
    cmp ax, 0
    je a20_fail

    mov ax, 0x9000           ; 0x90000/16 = 0x9000     
    mov ss, ax
    mov sp, 0xFFFE

    call a20_pass    
    jmp $
    ; setup gdt

    

a20_pass:
    mov si, a20_success_msg
    call print
    ret

a20_fail:
    push si
    mov si, a20_fail_msg
    call print
    jmp $

