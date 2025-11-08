;==============================================================================
; Function: check_a20
; Purpose: Checks whether the A20 line is enabled by the BIOS.
;          The A20 line allows the CPU to access memory above 1 MiB.
;          If the A20 line is disabled, any memory above 1 MiB wraps around
;          to start of low memory (below 1 MiB).
;
;          when a20 line is disalbed cpu can address 0x7c00 - 0x7dff and any address beyoud that
;          are wrapped around to start. here is simple check 
; 2. How the check_a20 function chooses addresses
;          We have two pairs:
;          Segment:Offset	Register	Physical address
;          ES:DI	ES=0x0000, DI=0x0500	0x0000*16 + 0x0500 = 0x0500 (below 1MB)
;          DS:SI	DS=0xFFFF, SI=0x0510	0xFFFF*16 + 0x0510 = 0xFFFF0 + 0x0510 = 0x100500 (above 1MB)
;          ES:DI → low memory below 1 MiB
;          DS:SI → high memory above 1 MiB
;          Check: 0x100500 − 0x0500 = 0x100000 = 1 MiB difference
;          If we write some thing to the higher address if a20 line is disabe then we get wrap to the 
;          orignal 0x500 location.

;          Returns: AX = 0 → A20 disabled (memory wraps)
;                   AX = 1 → A20           enabled (memory above 1 MiB accessible)
;
;          Notes:   This function is self-contained and preserves all registers and flags.
;==============================================================================

check_a20:
    pushf
    push ds
    push es
    push di
    push si
    
    cli                                     ; disable interrupts temporarily
    
    ; Set up low memory location (ES:DI) for testing
    xor ax, ax
    mov es, ax
    mov di, 0x0500                          ; offset in low memory
    
    mov al, byte [es:di]                    ; save original value at ES:DI
    push ax
    
    ; Set up high memory location (DS:SI) for testing (1 MiB above)
    xor ax, ax
    mov ds, ax
    mov si, 0x0510                          ; offset in high memory
    
    mov al, byte [ds:si]                    ; save original value at DS:SI
    push ax

    ; Write test values to low and high memory
    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF

    ; Compare low memory value to high memory value
    cmp [es:di], 0xFF                        ; if A20 disabled, memory wraps → values equal

    ; Restore original memory values
    pop ax
    mov byte [ds:si], al                     ; restore DS:SI
    pop ax
    mov byte [es:di], al                     ; restore ES:DI

    xor ax, ax                               ; default AX = 0 → assume A20 disabled
    je check_a20__exit                       ; if values equal → A20 disabled
    ; when the above condition fail then we continue sequentially and executed the below lable
    ; mov ax, 1                                ; values different → A20 enabled
    jmp enable_a20__fast_a20_gate


; Enable the a20 line via the fast-a20 gate method which is avaliable in new os
; The I/O port 0x92 is 1 byte and the 2nd bit (0,1<-this...7) is responsible for the a20 line
; when 2nd bit is 0 a20 is disabled and so we need to flip that to one
enable_a20__fast_a20_gate:
    in al, 0x92
    or al, 2                                ; al or 0000_0010 -> this will flip 2nd bit to 1 
    out 0x92, al                            ; write back value in al to 0x92 port

    call check_a20
    xor ax, ax
    je check_a20__exit

    mov ax, 1

check_a20__exit:
    pop si
    pop di
    pop es
    pop ds
    popf
    ret

