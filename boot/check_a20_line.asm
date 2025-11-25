;==============================================================================
; check_a20_line.asm - A20 line check and enable
;==============================================================================
bits 16

;------------------------------------------------------------------------------
; check_a20 - Check if A20 is enabled, enable if not
;------------------------------------------------------------------------------
; Returns: AX = 1 if A20 enabled successfully, 0 if failed
;
; Method:
;   1. Test if A20 already enabled
;   2. If not, enable via Fast A20 Gate (port 0x92)
;   3. Re-test to verify
; Enable the a20 line via the fast-a20 gate method which is avaliable in new os
; The I/O port 0x92 is 1 byte and the 2nd bit (0,1<-this...7) is responsible for the a20 line
; when 2nd bit is 0 a20 is disabled and so we need to flip that to one
;------------------------------------------------------------------------------
check_a20:
    pushf
    push ds
    push es
    push di
    push si

    cli

    ; Test if A20 already enabled
    call .test_a20
    cmp ax, 1
    je .done

    ; Enable A20 via Fast A20 Gate
    in al, 0x92
    or al, 2
    out 0x92, al

    ; Brief delay
    mov cx, 8
.delay:
    loop .delay

    ; Re-test
    call .test_a20

.done:
    pop si
    pop di
    pop es
    pop ds
    popf
    ret


;------------------------------------------------------------------------------
; .test_a20 - Test A20 line status
;------------------------------------------------------------------------------
; Internal function
; Returns: AX = 1 if enabled, 0 if disabled
;
; Tests by writing different values to addresses that would alias
; if A20 is disabled:
;   0x0000:0x0500 (physical 0x00500)
;   0xFFFF:0x0510 (physical 0x100500 or 0x00500 if A20 disabled)
;------------------------------------------------------------------------------
.test_a20:
    push bx

    ; Low memory: ES:DI = 0x0000:0x0500
    xor ax, ax
    mov es, ax
    mov di, 0x0500

    ; High memory: DS:SI = 0xFFFF:0x0510
    not ax
    mov ds, ax
    mov si, 0x0510

    ; Save original values
    mov al, [es:di]
    mov bl, al
    mov al, [ds:si]
    push ax
    push bx

    ; Write test pattern
    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF

    ; Compare
    mov al, [es:di]

    ; Restore originals
    pop bx
    mov [es:di], bl
    pop bx
    mov [ds:si], bl

    ; Return result
    cmp al, 0xFF
    mov ax, 0
    je .test_done
    mov ax, 1

.test_done:
    pop bx
    ret

