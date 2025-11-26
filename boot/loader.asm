[BITS 16]

global load_sectors

extern print           ; found in io.asm

loading_error db "Disk read error!", 0x0D,0x0A,0

; ------------------------------------------------------------------------------
; load_sectors
; ------------------------------------------------------------------------------
; Loads sectors from disk using BIOS INT 13h LBA extensions (AH=0x42)
;
; Inputs (via registers before call):
;   CX = number of sectors to read
;   DX = drive number (0x00=A:, 0x80=first hard disk)
;   ES:BX = destination buffer segment:offset
;   SI = pointer to qword containing starting LBA (little endian)
;
; Returns:
;   AX = 0   → Failed (disk error)
;   AX = 1   → Success
;
; Notes:
;   - Uses 16-byte Disk Address Packet (DAP)
;   - Caller must ensure buffer is large enough
; ------------------------------------------------------------------------------
load_sectors:
    pusha

    ; -------------------------------------------------------------------------
    ; Build Disk Address Packet (DAP) on stack
    ; -------------------------------------------------------------------------
    ; Layout:
    ;   Offset 0 : size (1 byte, 0x10)
    ;   Offset 1 : reserved (1 byte, 0)
    ;   Offset 2 : word: number of sectors to read
    ;   Offset 4 : word: buffer offset
    ;   Offset 6 : word: buffer segment
    ;   Offset 8 : qword: starting LBA (little endian)
    ; -------------------------------------------------------------------------

    sub sp, 16                ; allocate 16 bytes on stack
    mov byte [sp], 0x10       ; DAP size
    mov byte [sp+1], 0        ; reserved
    mov [sp+2], cx            ; number of sectors
    mov [sp+4], bx            ; buffer offset
    mov [sp+6], es            ; buffer segment

    ; LBA 4 byte and our reg are 2 byte so we have to divided and then load
    mov ax, [si]              ; lower 16 bits of LBA
    mov [sp+8], ax
    mov ax, [si+2]            ; next 16 bits of LBA
    mov [sp+10], ax
    mov ax, [si+4]            ; next 16 bits of LBA
    mov [sp+12], ax
    mov ax, [si+6]            ; upper 16 bits of LBA
    mov [sp+14], ax

    ; -------------------------------------------------------------------------
    ; BIOS call to read sectors
    ; -------------------------------------------------------------------------
    mov ah, 0x42              ; LBA read
    mov dl, dx                ; drive number
    lea si, [sp]              ; DS:SI → DAP (stack)
    int 0x13
    jc .disk_error            ; jump if carry, 0x13 set flag register cf to 1 on error

    mov ax, 1                 ; success
    add sp, 16                ; freeing 16 byte stack which we have reserved.
    popa
    ret

.disk_error:
    mov ax, 0                 ; failure
    add sp, 16
    pusha
    mov si, loading_error
    call print
    popa
    popa
    ret
