;==============================================================================
; bootloader.asm - Main bootloader file
;==============================================================================
bits 16
global start

start:
    jmp boot

;------------------------------------------------------------------------------
; Data Section
;------------------------------------------------------------------------------
msg             db "Zeen OS", 0x0D, 0x0A, 0
boot_message    db "Load...", 0x0D, 0x0A, 0
loading_error   db "Disk err", 0x0D, 0x0A, 0
loading_success db "OK!", 0x0D, 0x0A, 0

;------------------------------------------------------------------------------
; Boot Initialization
;------------------------------------------------------------------------------
boot:
    cli
    cld

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7BFF

    call ClearScreen

    mov si, msg
    call Print

    mov si, boot_message
    call Print

    ; Check and enable A20
    call check_a20
    cmp ax, 1
    jne halt

    ; Load kernel from sector 2
    ; mov ax, 0x0050
    ; mov es, ax
    ; xor bx, bx

    ; mov ah, 0x02
    ; mov al, 0x01
    ; mov ch, 0x00
    ; mov cl, 0x02
    ; mov dh, 0x00
    ; mov dl, 0x00
    ; int 0x13

    ; jc error
    ; jmp success

error:
    mov si, loading_error
    call Print
    jmp halt

success:
    mov si, loading_success
    call Print

    ; Jump to kernel
    mov eax, [0x500 + 0x18]
    jmp eax

halt:
    hlt
    jmp halt

;------------------------------------------------------------------------------
; Include external files
;------------------------------------------------------------------------------
%include "io.asm"
%include "check_a20_line.asm"

;------------------------------------------------------------------------------
; Boot Signature
;------------------------------------------------------------------------------
times 510 - ($ - $$) db 0
dw 0xAA55

