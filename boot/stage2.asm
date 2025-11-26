bits 16

global s2_start
extern a20_enable
extern print

a20_fail_msg db "Fail to activate A20 line exiting...", 0xD, 0xA, 0x0


s2_start:
    call a20_enable
    cmp ax, 1
    je a20_fail 

    ; setup gdt
    

a20_fail:
    push si
    mov si, a20_fail_msg
    call print
    jmp $
