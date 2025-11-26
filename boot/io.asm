;==============================================================================
; io.asm - I/O routines using BIOS interrupts
;==============================================================================
bits 16

;------------------------------------------------------------------------------
; Print - Output null-terminated string
;------------------------------------------------------------------------------
; Parameters:
;   DS:SI = Pointer to null-terminated string
;
; Uses BIOS INT 10h Teletype function
; Handles: regular chars, \r (0x0D), \n (0x0A)
;------------------------------------------------------------------------------
Print:
    pusha

    mov bh, 0                          ; Page 0
    mov bl, 0x0F                       ; White color

.loop:
    lodsb
    test al, al
    jz .done

    mov ah, 0x0E                       ; BIOS teletype
    int 0x10
    jmp .loop

.done:
    popa
    ret


;------------------------------------------------------------------------------
; ClearScreen - Clear display and reset cursor
;------------------------------------------------------------------------------
; Uses BIOS INT 10h to reset video mode
; This clears screen and moves cursor to (0,0)
;------------------------------------------------------------------------------
ClearScreen:
    push ax

    mov ah, 0x00                       ; Set video mode
    mov al, 0x03                       ; 80x25 text mode
    int 0x10

    pop ax
    ret

