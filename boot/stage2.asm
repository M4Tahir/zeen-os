bits 16

global s2_start
jmp s2_start

extern a20_enable
extern print
extern clear_screen

;------------------------------------------------------------------------------
; Data Section
;------------------------------------------------------------------------------
STACK_TOP equ 0x90000             ; Top of stack 0x90000 (576kb)
KERNEL_DATA_SEL equ 0x10    ; Offset 0x10 in our GDT
KERNEL_CODE_SEL equ 0x08    ; Offset 0x08 in our GDT

s2_message db "Starting stage 2...", 0x0D, 0xA, 0x0
a20_fail_msg db "Fail to activate A20 line, exiting...", 0xD, 0xA, 0x0
a20_success_msg db "Activated A20 line...", 0xD, 0xA, 0x0
pm_success_msg db "Successfully landed in 32-bit PM", 0

s2_start:
    call clear_screen
    mov si, s2_message
    call print

    ; return ax = 1 (a20 success) ax = 0 ( a20 fail)
    call a20_enable
    cmp ax, 0
    je a20_fail

    mov si, a20_success_msg
    call print

    ; PREPARE FOR PROTECTED MODE
    
    cli                     ; 1. Disable interrupts (crucial!)
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 0x1             ; Set PE (Protection Enable) bit
    mov cr0, eax

    ; This flushes the pipeline and forces the CPU to look at the new GDT
    ; 0x08 is the offset to our Code Segment defined below
    jmp KERNEL_CODE_SEL:pm_start

a20_fail:
    mov si, a20_fail_msg
    call print
    jmp $

;------------------------------------------------------------------------------
; 32-BIT PROTECTED MODE SECTION
;------------------------------------------------------------------------------
bits 32
pm_start:
    ; We are now in 32-bit mode. We must point all data segments to the 
    ; Data Selector (0x10) defined in our GDT.
    mov ax, KERNEL_DATA_SEL
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Setup Stack for C
    mov esp, STACK_TOP
    
    mov byte [0xB8000], 'P'
    mov byte [0xB8001], 0x02  
    mov byte [0xB8002], 'M'
    mov byte [0xB8003], 0x02
    
    ; extern kernel_main
    ; call kernel_main

    jmp $


;------------------------------------------------------------------------------
; THE BOOTSTRAP GDT 
;------------------------------------------------------------------------------
; We cannot use the C struct yet because we aren't in 32-bit mode.

gdt_start:

; 1. Null Descriptor (Offset 0x00) - Mandatory
    dd 0x0
    dd 0x0

; 2. Code Segment Descriptor (Offset 0x08)
; Base: 0x0, Limit: 0xFFFFF, Access: 0x9A, Flags: 0xCF
    dw 0xFFFF       ; Limit (bits 0-15)
    dw 0x0000       ; Base (bits 0-15)
    db 0x00         ; Base (bits 16-23)
    db 10011010b    ; Access Byte (Present, Ring0, Code, Exec/Read)
    db 11001111b    ; Flags (4KB blocks, 32-bit) + Limit (bits 16-19)
    db 0x00         ; Base (bits 24-31)

; 3. Data Segment Descriptor (Offset 0x10)
; Base: 0x0, Limit: 0xFFFFF, Access: 0x92, Flags: 0xCF
    dw 0xFFFF       ; Limit (bits 0-15)
    dw 0x0000       ; Base (bits 0-15)
    db 0x00         ; Base (bits 16-23)
    db 10010010b    ; Access Byte (Present, Ring0, Data, Read/Write)
    db 11001111b    ; Flags (4KB blocks, 32-bit) + Limit (bits 16-19)
    db 0x00         ; Base (bits 24-31)

gdt_end:

; The GDT Descriptor (this is what lgdt loads)
gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Limit (Size of GDT - 1)
    dd gdt_start                ; Base Address of GDT
