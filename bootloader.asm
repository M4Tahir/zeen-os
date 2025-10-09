;*********************************************************
; bootloader.asm
; A simple boot loader - prints a welcome message using VGA text mode routines
;*********************************************************

org 0x7c00
bits 16

start: 
    jmp boot

boot:
    cli                 ; Disable interrupts during setup
    cld                 ; Clear direction flag

    ;-----------------------------------------------------
    ; Set up DS:SI to point to the message for Print
    ; DS = segment of this code (0x7c0)
    ; SI = offset of msg
    ;-----------------------------------------------------
;    mov ax, 0x7c0       ; Segment portion of 0x7c00
;    mov ds, ax
;    mov si, msg         ; SI = offset of message

    mov ax, 0
    mov ds, ax
    mov si, msg

    call ClearScreen

;    mov bh, 10
;    mov bl, 5
;    call MoveCursor
   
    
    mov bh, 0
    mov bl, 0
    call MoveCursor
    
    call Print

    ;hlt                 ; Halt system stop executing instruction and go idle until interrupts if int are disabled then cpu remain idel forever.
     jmp $             ; jump to the current instruction


;---------------------------------------------------------
;  Boot message - null terminated
; 0ah -> \n odh -> \r  oh -> \0
;---------------------------------------------------------
msg db "Welcome to Zeen OS!", 0h


%include "io.asm"

;---------------------------------------------------------
; Pad to 510 bytes, then add boot signature 0xAA55
;---------------------------------------------------------
times 510 - ($ - $$) db 0 ; $ current instruction - $$ address of current section
dw 0xAA55              ; Boot signatur

