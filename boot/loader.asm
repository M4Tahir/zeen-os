[BITS 16]

global load_sectors
extern print                ; found in io.asm

loading_error db "Disk read error!", 0x0D, 0x0A, 0

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
;   AX = 0 → Failed (disk error)
;   AX = 1 → Success
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
    ;   Offset 0  : size (1 byte, 0x10)
    ;   Offset 1  : reserved (1 byte, 0)
    ;   Offset 2  : word: number of sectors to read
    ;   Offset 4  : word: buffer offset
    ;   Offset 6  : word: buffer segment
    ;   Offset 8  : qword: starting LBA (little endian)
    ; -------------------------------------------------------------------------
    
    sub sp, 16              ; Reserve 16 bytes on stack for DAP
    
    ; Build DAP in stack memory
    mov byte [ss:bp-16], 0x10    ; DAP size = 16 bytes
    mov byte [ss:bp-15], 0       ; Reserved byte, must be 0
    mov [ss:bp-14], cx           ; Number of sectors to read (word)
    mov [ss:bp-12], bx           ; Buffer offset (word)
    mov [ss:bp-10], es           ; Buffer segment (word)
    
    ; LBA (starting sector) is 8 bytes (qword), split into 4 words
    mov ax, [si]                 ; Load lower 16 bits of LBA from [SI]
    mov [ss:bp-8], ax            ; Store lower 16 bits into DAP
    mov ax, [si+2]               ; Load next 16 bits of LBA
    mov [ss:bp-6], ax            ; Store next 16 bits
    mov ax, [si+4]               ; Load next 16 bits of LBA
    mov [ss:bp-4], ax            ; Store next 16 bits
    mov ax, [si+6]               ; Load upper 16 bits of LBA
    mov [ss:bp-2], ax            ; Store upper 16 bits
    
    ; -------------------------------------------------------------------------
    ; BIOS call to read sectors
    ; -------------------------------------------------------------------------
    mov ah, 0x42                 ; Extended read function
    ; DX already contains drive number from caller
    mov si, sp                   ; SI points to DAP on stack
    int 0x13                     ; Call BIOS
    
    jc .disk_error               ; Jump if carry flag set (error)
    
    ; Success path
    add sp, 16                   ; Clean up stack
    popa
    mov ax, 1                    ; Return success
    ret

.disk_error:
    add sp, 16                   ; Clean up stack
    popa
    
    ; Print error message
    push si
    mov si, loading_error
    call print
    pop si
    
    xor ax, ax                   ; Return 0 (failure)
    ret
