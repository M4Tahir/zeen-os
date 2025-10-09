;==============================================================================
; bootloader.asm - Zeen OS Master Boot Record
;==============================================================================
; A minimal x86 bootloader that initializes the system and displays a welcome
; message using VGA text mode. Loaded by BIOS at 0x7C00.
;
; Boot Process:
;   1. BIOS loads this 512-byte sector to 0x7C00
;   2. CPU starts execution at 0x7C00 in real mode
;   3. Bootloader initializes segment registers
;   4. Clears screen and displays welcome message
;   5. Halts execution (infinite loop)
;
; Memory Layout:
;   0x0000:0x7C00 - Bootloader code (512 bytes)
;   0xB800:0x0000 - VGA text mode buffer
;
; Requirements:
;   - x86 CPU (8086+)
;   - BIOS with INT 13h disk services
;   - VGA-compatible display adapter
;==============================================================================

org 0x7C00                             ; BIOS loads boot sector here
bits 16                                ; Real mode (16-bit)

;------------------------------------------------------------------------------
; Entry Point
;------------------------------------------------------------------------------
start:
    jmp boot

;------------------------------------------------------------------------------
; Boot Initialization
;------------------------------------------------------------------------------
; Initializes CPU state and segment registers for proper operation.
; Must be done before accessing data or calling functions.
;------------------------------------------------------------------------------
boot:
    cli                                ; Disable interrupts during setup
    cld                                ; Clear direction flag (string ops forward)

    ;--------------------------------------------------------------------------
    ; Initialize segment registers
    ;--------------------------------------------------------------------------
    ; We use segment 0x0000 for simplicity. The bootloader is loaded at
    ; 0x7C00 physical address, which is 0x0000:0x7C00 in segment:offset form.
    ;
    ; Alternative: Use 0x07C0:0x0000 (same physical address)
    ;   mov ax, 0x07C0
    ;   mov ds, ax
    ;   mov si, msg - 0x7C00          ; Adjust offset accordingly
    ;--------------------------------------------------------------------------
    xor ax, ax
    mov ds, ax                         ; DS = 0x0000
    mov es, ax                         ; ES = 0x0000 (for string operations)
    mov ss, ax                         ; SS = 0x0000 (stack segment)
    mov sp, 0x7C00                     ; SP = 0x7C00 (stack grows downward)

    ;--------------------------------------------------------------------------
    ; Display welcome message
    ;--------------------------------------------------------------------------
    call ClearScreen                   ; Erase screen and reset cursor

    mov si, msg
    call Print

    ;--------------------------------------------------------------------------
    ; Halt system
    ;--------------------------------------------------------------------------
    ; The bootloader's job is done. In a real OS, this would load the kernel.
    ; For now, we simply halt with an infinite loop.
    ;--------------------------------------------------------------------------
    jmp $                              ; Infinite loop ($ = current address)


;==============================================================================
; Data Section
;==============================================================================

;------------------------------------------------------------------------------
; Boot Message
;------------------------------------------------------------------------------
; Null-terminated string displayed on boot.
; ASCII control codes:
;   0x0A = Line Feed (LF, \n)
;   0x0D = Carriage Return (CR, \r)
;   0x00 = Null terminator
;------------------------------------------------------------------------------
msg:
    db "Welcome to Zeen OS!", 0x00


;==============================================================================
; Include VGA I/O Library
;==============================================================================
; Provides: ClearScreen, MoveCursor, Print, PutChar, and cursor management
;==============================================================================
%include "io.asm"


;==============================================================================
; Boot Sector Signature
;==============================================================================
; The BIOS requires the last two bytes of the boot sector to be 0xAA55.
; This signature identifies the sector as bootable.
;
; Padding calculation:
;   510 = 512 bytes (sector size) - 2 bytes (signature)
;   ($ - $$) = current position - section start = bytes written so far
;   Remaining bytes are filled with zeros
;==============================================================================
times 510 - ($ - $$) db 0              ; Pad to 510 bytes
dw 0xAA55                              ; Boot signature (little-endian)


;==============================================================================
; End of bootloader.asm
;==============================================================================
