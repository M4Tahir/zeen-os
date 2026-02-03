bits 16

global s2_start
jmp s2_start

extern a20_enable
extern print
extern clear_screen
global gdt_flush

;------------------------------------------------------------------------------
; Data Section
;------------------------------------------------------------------------------
STACK_TOP equ 0x90000                ; Top of stack 0x90000 (576kb)
STACK_BOTTOM equ 0x80000             ; Bottom of stack 64kb of stack.(not used just for rem)
KERNEL_DATA_SEL equ 0x10    ; Entry 2 (index 2, selector = 2 * 8 = 0x10)
KERNEL_CODE_SEL equ 0x08    ; Entry 1 (index 1, selector = 1 * 8 = 0x08)

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
    call gdt_flush


a20_pass:
    mov si, a20_success_msg
    call print
    ret

a20_fail:
    push si
    mov si, a20_fail_msg
    call print
    jmp $

gdt_flush:
    cli

    ; Load GDT pointer from stack parameter
    mov eax, [esp + 4]      ; Get first parameter (gdt_ptr address)
    lgdt [eax]              ; Load GDT
    ; Enable protected mode by setting PE bit in CR0
    mov eax, cr0
    or al, 0x1                ; Set PE (Protection Enable) bit
    mov cr0, eax
    
    ; Far jump to flush CPU pipeline and load CS with kernel code selector
    jmp KERNEL_CODE_SEL:pm_start

bits 32
pm_start:
    jmp $
    mov ax, KERNEL_DATA_SEL
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    mov esp, STACK_TOP
    
    ; Test: Write directly to VGA text mode video memory
    ; Video memory starts at 0xB8000
    ; Format: [character byte][attribute byte] for each cell
    ; Attribute byte: [background(4 bits)][foreground(4 bits)]
    
    mov byte [0xB8000], 'P'
    mov byte [0xB8001], 0x0F    ; White on black
    
    mov byte [0xB8002], 'M'
    mov byte [0xB8003], 0x0F
    

    jmp $

