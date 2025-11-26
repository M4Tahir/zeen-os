; ==============================================================================
; Kernel_entry.asm - Setup stack, enable A20, setup temporary GDT, enter PM
; Author: Zeen OS style
; Notes:
;   - Kernel loaded at 0x10000 (64 KB)
;   - Temporary stack at 0x90000 (576 KB)
;   - Minimal GDT defined here; full GDT loaded in kmain
; ==============================================================================
[org 0x10000]
[bits 16]

; --------------------------------------------------------------------------
; Data
; --------------------------------------------------------------------------
A20_FAIL    db "Fail to enable A20 line", 0x0D, 0x0A, 0

msg_pm      db "Entering protected mode...", 0x0D, 0x0A, 0

; --------------------------------------------------------------------------
; External references
; --------------------------------------------------------------------------
global _start
extern kmain
;extern A20_ENABLE
;extern Print

; --------------------------------------------------------------------------
; Entry point
; --------------------------------------------------------------------------
_start:
    cli                     ; disable interrupts

    ; -----------------------------
    ; Zero out segments (real mode)
    ; -----------------------------
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ax, 0x9000
    mov ss, ax
    xor sp, sp              ; SP = 0 → stack at 0x90000

    ; -----------------------------
    ; Enable A20 line
    ; -----------------------------
    call A20_ENABLE
    cmp ax, 1
    je .La20_failure

    ; -----------------------------
    ; Minimal GDT (temporary) - for PM entry
    ; We will setup the gdt in main function in c later.
    ; -----------------------------
align 8
gdt_start:

gdt_null:                   ; selector 0x00
    dd 0x0
    dd 0x0

gdt_code:                   ; selector 0x08
    dw 0xFFFF               ; limit low
    dw 0x0000               ; base low
    db 0x00                 ; base middle
    db 10011010b            ; access
    db 11001111b            ; flags
    db 0x00                 ; base high

gdt_data:                   ; selector 0x10
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00

gdt_end:

gdtr:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; -----------------------------
; Segment selector definitions
; -----------------------------
CODE_SEG    equ 0x08
DATA_SEG    equ 0x10

; --------------------------------------------------------------------------
; Protected Mode Start
; --------------------------------------------------------------------------
[BITS 32]
protected_mode_start:

    ; -----------------------------
    ; Load data segments in PM
    ; -----------------------------
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; -----------------------------
    ; Setup linear stack (flat memory)
    ; -----------------------------
    mov esp, 0x90000        ; 576 KB temporary stack

    ; -----------------------------
    ; Optional: write a PM message to screen
    ; -----------------------------
    mov ebx, 0xb8000
    mov byte [ebx], 'P'
    mov byte [ebx+1], 0x0F
    mov byte [ebx+2], 'M'
    mov byte [ebx+3], 0x0F

    ; -----------------------------
    ; Jump to kernel main (C code)
    ; -----------------------------
    call kmain

    ; --------------------------------
    ; Should never return here
    ; --------------------------------
    jmp $

; --------------------------------------------------------------------------
; A20 Failure handler
; --------------------------------------------------------------------------
.La20_failure:
    mov si, A20_FAIL
    call Print
    jmp $

%include "a20.asm"
%include "io.asm"

