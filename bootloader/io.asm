;==============================================================================
; io.asm - VGA Text Mode I/O Library
;==============================================================================
; A lightweight VGA text mode (80x25) driver for x86 real mode operating systems.
; Provides low-level cursor management, character rendering, and screen operations.
;
; Target: 16-bit real mode (8086+)
; VGA Memory: 0xB800:0000 (CGA/EGA/VGA compatible)
; Screen Size: 80 columns × 25 rows
;==============================================================================

bits 16

section .data
    cursor_pos dw 0                    ; Current cursor offset in VGA buffer

section .text

;------------------------------------------------------------------------------
; MoveCursor - Set logical cursor position
;------------------------------------------------------------------------------
; Sets the software cursor position and synchronizes the hardware cursor.
; The position is calculated as a linear offset in the VGA text buffer.
;
; Parameters:
;   BH = Row (Y coordinate, 0-24)
;   BL = Column (X coordinate, 0-79)
;
; Returns:
;   None
;
; Modifies:
;   cursor_pos, hardware cursor position
;
; Formula:
;   offset = ((row * 80) + column) * 2
;   Note: Multiplied by 2 because each cell = 1 byte char + 1 byte attribute
;------------------------------------------------------------------------------
MoveCursor:
    push ax
    push bx

    xor ax, ax
    mov al, bh                         ; AL = row
    push bx
    mov bx, 80
    mul bx                             ; AX = row * 80
    pop bx
    
    xor bh, bh                         ; BX = column only
    add ax, bx                         ; AX = (row * 80) + column
    shl ax, 1                          ; AX *= 2 (byte offset)
    
    mov [cursor_pos], ax

    ; Sync hardware cursor
    shr ax, 1                          ; Convert back to character position
    mov bx, ax
    call SetHardwareCursorPos

    pop bx
    pop ax
    ret


;------------------------------------------------------------------------------
; SetHardwareCursorPos - Update VGA hardware cursor
;------------------------------------------------------------------------------
; Programs the VGA CRTC (CRT Controller) to position the blinking cursor.
; The cursor position is a 16-bit value split across two 8-bit registers.
;
; Parameters:
;   BX = Character position (0-1999)
;        BH = High byte of position
;        BL = Low byte of position
;
; I/O Ports:
;   0x3D4 = CRTC Index Register (selects internal register)
;   0x3D5 = CRTC Data Register (read/write selected register)
;
; CRTC Registers Used:
;   0x0E = Cursor Location High Byte
;   0x0F = Cursor Location Low Byte
;------------------------------------------------------------------------------
SetHardwareCursorPos:
    push ax
    push dx

    ; Write high byte
    mov dx, 0x3D4
    mov al, 0x0E                       ; Select cursor high register
    out dx, al
    
    inc dx                             ; DX = 0x3D5 (data port)
    mov al, bh
    out dx, al

    ; Write low byte
    dec dx                             ; DX = 0x3D4 (index port)
    mov al, 0x0F                       ; Select cursor low register
    out dx, al
    
    inc dx                             ; DX = 0x3D5 (data port)
    mov al, bl
    out dx, al

    pop dx
    pop ax
    ret


;------------------------------------------------------------------------------
; UpdateHardwareCursor - Sync hardware cursor with software position
;------------------------------------------------------------------------------
; Internal helper that reads cursor_pos and updates the hardware cursor.
; Converts the byte offset to a character index before programming the VGA.
;------------------------------------------------------------------------------
UpdateHardwareCursor:
    push ax
    push bx
    
    mov ax, [cursor_pos]               ; Get byte offset
    shr ax, 1                          ; Convert to character index
    mov bx, ax
    call SetHardwareCursorPos
    
    pop bx
    pop ax
    ret


;------------------------------------------------------------------------------
; PutChar - Write character(s) to screen at cursor position
;------------------------------------------------------------------------------
; Renders one or more characters with the specified attribute at the current
; cursor position. Automatically advances cursor and syncs hardware cursor.
;
; Parameters:
;   AL = ASCII character to print
;   BL = Attribute byte (bits 0-3: foreground, bits 4-6: background, bit 7: blink)
;   CX = Repeat count (number of times to print the character)
;
; Attribute Byte Format:
;   Bit 7    | Bits 6-4  | Bits 3-0
;   Blink    | Background| Foreground
;
; Common Colors:
;   0x0 = Black    0x8 = Dark Gray
;   0x1 = Blue     0x9 = Light Blue
;   0x2 = Green    0xA = Light Green
;   0x3 = Cyan     0xB = Light Cyan
;   0x4 = Red      0xC = Light Red
;   0x5 = Magenta  0xD = Light Magenta
;   0x6 = Brown    0xE = Yellow
;   0x7 = Lt Gray  0xF = White
;------------------------------------------------------------------------------
PutChar:
    push di
    push es
    push cx
    push ax

    mov di, 0xB800
    mov es, di
    mov di, [cursor_pos]

.repeat:
    mov byte [es:di], al               ; Write character
    inc di
    mov byte [es:di], bl               ; Write attribute
    inc di
    loop .repeat

    mov [cursor_pos], di

    pop ax
    pop cx
    pop es
    pop di

    call UpdateHardwareCursor
    ret


;------------------------------------------------------------------------------
; Print - Output null-terminated string
;------------------------------------------------------------------------------
; Renders a string at the current cursor position using default white-on-black
; attribute. The cursor automatically advances after each character.
;
; Parameters:
;   DS:SI = Pointer to null-terminated string
;
; Notes:
;   - String must be terminated with 0x00
;   - Uses default attribute 0x0F (white on black)
;   - Preserves all registers except flags
;------------------------------------------------------------------------------
Print:
    push ax
    push bx
    push cx
    push si

.loop:
    lodsb                              ; AL = [DS:SI++]
    test al, al                        ; Check for null terminator
    jz .done

    ; checking for \n 
    cmp al, 0x0A                       ; checking for \n character
    je .newline  

    cmp al, 0x0D                       ; check for \r 
    je .cr
    
    mov bl, 0x0F                       ; White on black
    mov cx, 1
    call PutChar
    jmp .loop

.newline:
    call NewLine
    jmp .loop

.cr:
    call CarriageReturn
    jmp .loop

.done:
    pop si
    pop cx
    pop bx
    pop ax
    ret


;------------------------------------------------------------------------------
; ClearScreen - Erase entire display
;------------------------------------------------------------------------------
; Fills the entire 80x25 screen with spaces using optimized REP STOSW.
; Resets the cursor to the top-left corner (0,0).
;
; Performance:
;   Uses REP STOSW for maximum speed (2000 words = 4000 bytes in ~2000 cycles)
;
; Notes:
;   - Clears to spaces (0x20) with white-on-black attribute (0x0F)
;   - Much faster than calling PutChar 2000 times
;   - Resets both software and hardware cursor positions
;------------------------------------------------------------------------------
ClearScreen:
    push ax
    push cx
    push es
    push di

    mov ax, 0xB800
    mov es, ax
    xor di, di

    mov ax, 0x0F20                     ; AH=attribute (0x0F), AL=space (0x20)
    mov cx, 2000                       ; 80 * 25 characters
    rep stosw                          ; Fill screen buffer

    mov word [cursor_pos], 0

    pop di
    pop es
    pop cx
    pop ax

    call UpdateHardwareCursor
    ret


;==============================================================================
; NewLine: This will print \n or new line to the vga memory 
; Note: this will only do the new line not return the cursor to the begennin of the screen
;==============================================================================
NewLine:
    push ax
    push bx
    push cx
    push dx

    mov ax, [cursor_pos]     ; AX = byte offset
    shr ax, 1                ; divide by 2 → character index
    xor dx, dx               ; clear DX for division
    mov cx, 80
    div cx                   ; div: dx:ax, ax=quotient, dx=remainder: AX = row, DX = col

    inc ax                   ; next row

    mov bx, 80
    mul bx                   ; AX = row * 80
    add ax, dx               ; AX = row*80 + col (col=0 here)
    shl ax, 1                ; AX *= 2 (byte offset)
    mov [cursor_pos], ax     ; save new position

    call UpdateHardwareCursor ; sync hardware cursor

    pop dx
    pop cx
    pop bx
    pop ax
    ret

;==============================================================================
; CarriageReturn: \r This will move the cursor to the begenning of the currnt line 
;==============================================================================
CarriageReturn:
    push ax
    push bx
    push cx
    push dx

    mov ax, [cursor_pos]     ; AX = byte offset
    shr ax, 1                ; divide by 2 → character index
    xor dx, dx               ; clear DX for division
    mov cx, 80
    div cx                   ; div: dx:ax, ax=quotient, dx=remainder: AX = row, DX = col

    xor dx, dx               ; start column = 0

    mov bx, 80
    mul bx                   ; AX = row * 80
    add ax, dx               ; AX = row*80 + col (col=0 here)
    shl ax, 1                ; AX *= 2 (byte offset)
    mov [cursor_pos], ax     ; save new position

    call UpdateHardwareCursor ; sync hardware cursor

    pop dx
    pop cx
    pop bx
    pop ax
    ret 

;==============================================================================
; End of io.asm
;==============================================================================
