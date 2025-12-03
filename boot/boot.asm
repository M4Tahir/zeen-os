;==============================================================================
; boot.asm - Main bootloader file
;==============================================================================
bits 16
global start

msg             db "Zeen OS", 0x0D, 0x0A, 0
boot_message    db "Loading...", 0x0D, 0x0A, 0
loading_success db "OK!", 0x0D, 0x0A, 0
loading_error db "Disk read error!", 0x0D,0x0A,0


start:
    jmp boot

;------------------------------------------------------------------------------
; Boot Initialization
;------------------------------------------------------------------------------
boot:
    cli
    cld

    xor ax, ax
    mov ds, ax
    mov es, ax

    ;    Address Range          | Region                           | Size
    ;    -----------------------|----------------------------------|----------
    ;    0x00000 - 0x003FF      | Interrupt Vector Table (IVT)    | 1 KB
    ;    0x00400 - 0x004FF      | BIOS Data Area                  | 256 bytes
    ;    0x00500 - 0x07BFF      | Free (usable)                   | ~30 KB
    ;    0x07C00 - 0x07DFF      | Loaded Boot Sector              | 512 bytes
    ;    0x07E00 - 0x7FFFF      | Free (usable)                   | ~480 KB
    ;    0x80000 - 0x9FBFF      | Free (usable)                   | ~127 KB
    ;    0x9FC00 - 0x9FFFF      | Extended BIOS Data Area (EBDA)  | ~1 KB
    ;    0xA0000 - 0xBFFFF      | Video Memory                    | 128 KB
    ;    0xC0000 - 0xFFFFF      | BIOS ROM                        | 256 KB
    ;    0x100000+              | Free (Extended Memory)          | 1 MB+

    ; Stack top start below the EBDA regsion from 576kb region toward the kernal load address
    ; SS:SP = 0x9000:0x0000
    ; physical = 0x9000 * 16 + 0x0000 = 0x90000 (576kb)

    mov ax, 0x9000           ; 0x90000/16 = 0x9000     
    mov ss, ax
    mov sp, 0x0000

    call clear_screen
    mov si, msg
    call print
    mov si, boot_message
    call print

    ; Load stage 2 from second sector and jump to start of it;
    ; we will load the sector right after 0x7c00 + 512byte and jump to it start
    ; ES:BX = 0x7e0:0x000 -> 0x7c00
  
    ; Load Stage 2 (1 sector) immediately after Stage 1
    mov ax, 0x07E0      ; ES = 0x07E0
    mov es, ax
    xor bx, bx          ; BX = 0 → ES:BX = 0x07E0:0x0000 → 0x7E00

    mov ah, 0x02        ; BIOS: read sectors
    mov al, 0x01        ; number of sectors to read
    mov ch, 0x00        ; first hard disk
    mov cl, 0x02        ; sector (second sector)
    mov dh, 0x00        ; head
    mov dl, 0x80        ; drive number (first hard disk 0x80)
    int 0x13
    jc error             ; jump if error
    jmp success


error:
    mov si, loading_error
    call print
    jmp halt

success:
    mov si, loading_success
    call print

    jmp 0x07E0:0x0000   ; jump to Stage 2 start

halt:
    hlt
    jmp halt

print:
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


clear_screen:
    push ax

    mov ah, 0x00                       ; Set video mode
    mov al, 0x03                       ; 80x25 text mode
    int 0x10

    pop ax
    ret

;------------------------------------------------------------------------------
; Include external files: not needed to be included, as they will be resolved by the linker
;------------------------------------------------------------------------------
; %include "io.asm"

;------------------------------------------------------------------------------
; Boot Signature
;------------------------------------------------------------------------------
times 510 - ($ - $$) db 0
dw 0xAA55

