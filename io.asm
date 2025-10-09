;******************************************************************************
; io.asm
; VGA text mode direct output routines for a simple OS (80x25 screen).
; Provides cursor movement, character printing, string printing, and screen clearing.
; All routines are designed for 16-bit real mode and interact directly with VGA text memory.
;******************************************************************************

bits 16

; Stores the current cursor offset within the VGA text buffer.
cursor_pos dw 0

;---------------------------------------------------------
; MovCursor
; Moves the logical cursor to a specified row and column, updating cursor_pos.
; Parameters:
;   bh = Y coordinate (row, 0-based)
;   bl = X coordinate (column, 0-based)
; Returns:
;   None (cursor_pos is updated)
; Formula:
;   offset = ((Y * 80) + X) * 2 => As we are storing the buffer as 1D instead of 2D array that is why we use this.
;   Each character cell uses 2 bytes: one for ASCII, one for attribute (color).
;---------------------------------------------------------

MoveCursor:
    push ax
    push bx

    xor ax, ax
    mov al, bh                ; Load Y coordinate
    xor bx,bx
    mov bx, 80                ; 80 rows total
    mul bx                    ; ax = Y * 80

    pop bx                    ; Restore bx (X coordinate in bl)
    xor bh, bh                ; Ensure X is in bl, bh=0
    add ax, bx                ; ax = (Y * 80) + X

    shl ax, 1                 ; Multiply by 2: each char = 2 bytes
    mov [cursor_pos], ax      ; Store new cursor offset
    
    pop ax
    ret


;---------------------------------------------------------
; SetHardwareCursorPos 
; Set the position of the blinking cursor position. The VGA cursor is stored inside the VGA 
; controller as 16 bit character index and you can access it through I/O port 0x3D4 and 0x3D5
; using the internal CRTC register 0x0E and 0x0F
; Parameters:
;   bx = character position (0-1999 for 80x25 screen)
; Port: 0x3D4 -> Index register (register which we want to talk with inside CRTC)
; Port: 0x3D5 -> Data register (read/write the value of chosen register)
; IN -> read byte from port dx into al
; OUT -> write byte in AL to port dx
;---------------------------------------------------------

SetHardwareCursorPos:
    push ax
    push dx

    mov dx, 0x3D4               ; index register setting mode.
    mov al, 0x0E                ; 0x0E to select high byte register
    out dx, al                  ; write content of al to dx (port)

    inc dx                      ; 0x3D5 means we want to write to the register.
    mov al, bh                  ; get the high byte from bh register
    out dx, al                  ; write al content to dx

    dec dx                      ; 0x3D4
    mov al, 0x0F                ; 0x0F select low byte.
    out dx, al                  

    inc dx
    mov al, bl
    out dx, al

    pop dx
    pop ax
    ret


;---------------------------------------------------------
; UpdateHardwareCursor
; Helper function to sync hardware cursor with cursor_pos
; Reads cursor_pos, converts to character index, and updates hardware cursor
;---------------------------------------------------------

UpdateHardwareCursor:
    push ax
    push bx
    
    mov ax, [cursor_pos]
    shr ax, 1 
    mov bx, ax
    call SetHardwareCursorPos
    
    pop bx
    pop ax
    ret


;---------------------------------------------------------
; PutChar
; Prints a character at the current cursor position in VGA text mode.
; Parameters:
;   al = character to print
;   bl = color attribute (upper 4 bits: foreground, lower 4 bits: background)
;   cx = number of times to repeat the character
;   [cursor_pos] = offset in VGA memory to print at
; Details:
;   Writes directly to 0xb800:0 (VGA text buffer, real mode segment)
;   After printing, cursor_pos is updated to the next cell.
;---------------------------------------------------------

PutChar:
    push di
    push es
    push cx
    push ax

    mov di, 0xb800            ; VGA text segment
    mov es, di

    mov di, [cursor_pos]      ; Get current cursor offset

.repeat:
    mov byte [es:di], al      ; Write ASCII character [es:di] => real mode access segment*16+offset
    inc di
    mov byte [es:di], bl      ; Write attribute (color)
    inc di                    ; Advance to next cell

    loop .repeat
    mov [cursor_pos], di      ; Update cursor position

    pop ax
    pop cx
    pop es
    pop di

    call UpdateHardwareCursor
    ret

;---------------------------------------------------------
; Print
; Prints a null-terminated string at the current cursor position.
; Parameters:
;   ds:si = pointer to string
;   [cursor_pos] = offset in VGA memory
; Details:
;   Each character is printed using PutChar, in white-on-black by default.
;   Cursor position is advanced automatically.
;---------------------------------------------------------


Print:
    push ax
    push bx
    push cx
    push si

    xor ax,ax

.loop:
    lodsb                     ; Load next byte from [ds:si] into al, si++ so we point to next char
;    or al, al                 ; Check for null terminator
;    jz .done
    cmp al, 0
    je .done


    mov bl, 0x0f
    mov cx, 1
    call PutChar

    jmp .loop

.done:
    pop si
    pop cx
    pop bx
    pop ax
    ret


;---------------------------------------------------------
; ClearScreen
; Efficiently clears the entire screen buffer (80x25) to spaces, using a single color.
; Uses REP STOSW to rapidly fill memory.
; After clearing, resets cursor_pos to zero.
;---------------------------------------------------------

ClearScreen:
    push ax
    push es
    push di

    mov ax, 0xb800            ; VGA memory location
    mov es, ax                ; ES = VGA text segment
    xor di, di                ; DI = 0 (start of buffer)

    ; Prepare AX for REP STOSW:
    ; AH = attribute byte (color), AL = space character (' ')
    mov ah, 0x0f              ; White foreground, black background (0x0f)
    mov al, 0x20              ; Space character (' ')
    mov cx, 2000              ; 80 x 25 = 2000 character cells

    ; REP STOSW will write AX to [ES:DI], 2000 times (filling all screen cells)
    ; Each iteration writes 2 bytes: ASCII char + color attribute
    ; look below comment for the classical loop way
    rep stosw

    mov word [cursor_pos], 0  ; Reset cursor position

    pop di
    pop es
    pop ax

    call UpdateHardwareCursor
    ret

; ClearScreen:
;     push ax
;     push es
;     push di
;     push bx
;     push cx
; 
;     mov ax, 0xb800
;     mov es, ax
;     xor di, di
; 
;     mov al, 0x20        ; space character
;     mov bl, 0x0f        ; white on black
;     mov cx, 2000        ; 80*25 = 2000 chars
; 
; .clear
;     call PutChar
;     loop .clear
; 
;     mov word [cursor_pos], 0 ; reset cursor to 0
; 
;     pop cx
;     pop bx
;     pop di
;     pop es
;     pop ax
;     ret


;---------------------------------------------------------
; End of io.asm
;---------------------------------------------------------


