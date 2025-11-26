; ==============================================================================
; A20 Line Control (Real Mode)
; ==============================================================================
; Provides: A20_ENABLE
; Attempts enabling A20 repeatedly (A20_ENABLE_LOOPS times).
; ==============================================================================

BITS 16

A20_ENABLE_LOOPS     equ 255         ; Maximum retry attempts

; ==============================================================================
; A20_ENABLE
; Enable the A20 line. Tries multiple times:
;   1. Test A20
;   2. Enable via KBC
;   3. Enable via Fast A20 Gate (port 0x92)
; Returns:
;       AX = 1    A20 successfully enabled  
;       AX = 0    Failed after all retries
; ==============================================================================

A20_ENABLE:
        pushf
        push ds
        push es
        push si
        push di

        cli

        mov     cx, A20_ENABLE_LOOPS

.Lloop:
        call    .Ltest_a20
        cmp     ax, 1
        je      .Ldone

        ; Try keyboard-controller method
        call    .La20_kbc_enable

        ; Try Fast A20 Gate
        call    .Lfast_a20

        loop    .Lloop

        ; Retries exhausted, failure
        mov     ax, 0
        jmp     .Lexit


; ==============================================================================
; .Lfast_a20  - Enable A20 using port 0x92 Fast A20 Gate.
; ==============================================================================

.Lfast_a20:
        pusha

        in      al, 0x92
        or      al, 00000010b
        out     0x92, al

        popa
        ret


; ==============================================================================
; .La20_kbc_enable – Legacy keyboard controller A20 enabling (stub)
; ==============================================================================

.La20_kbc_enable:
        pusha
        ; TODO: KBC command sequence (0x64/0x60)
        popa
        ret


; ==============================================================================
; .Ltest_a20  - Test A20 by comparing aliased memory
; Returns:
;       AX = 1    A20 enabled
;       AX = 0    A20 disabled
; ==============================================================================

.Ltest_a20:
        push    bx

        ; ES:DI = 0000:0500
        xor     ax, ax
        mov     es, ax
        mov     di, 0x0500

        ; DS:SI = FFFF:0510
        not     ax
        mov     ds, ax
        mov     si, 0x0510

        ; Save low and high memory bytes
        mov     al, [es:di]
        mov     bl, al
        mov     al, [ds:si]
        push    ax
        push    bx

        ; Write test pattern
        mov     byte [es:di], 0x00
        mov     byte [ds:si], 0xFF

        ; Check if value wrapped around
        mov     al, [es:di]

        ; Restore low mem
        pop     bx
        mov     [es:di], bl

        ; Restore high mem
        pop     bx
        mov     [ds:si], bl

        ; Compare
        cmp     al, 0xFF
        mov     ax, 0
        je      .Ltest_done

        mov     ax, 1

.Ltest_done:
        pop     bx
        ret


; ==============================================================================
; Restore registers and return
; ==============================================================================

.Ldone:
        mov     ax, 1

.Lexit:
        pop     di
        pop     si
        pop     es
        pop     ds
        popf
        ret
