;==============================================================================
; bootloader.asm;
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

;org 0x7C00                             ; BIOS loads boot sector here
bits 16                                ; Real mode (16-bit)

;------------------------------------------------------------------------------
; Entry Point
;------------------------------------------------------------------------------
; This is for the linker ld so i can find id
global start

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
    ;mov sp, 0x7C00                     ; SP = 0x7C00 (stack grows downward)
    mov sp, 0x7BFF                     ; As the code is loaded into 0x7c00 region so we set up stack pointer so that we don't override the code.

    ;--------------------------------------------------------------------------
    ; Display welcome message
    ;--------------------------------------------------------------------------
    call ClearScreen                   ; Erase screen and reset cursor

    mov si, msg
    call Print

    mov si, boot_message
    call Print

      
    ;------------------------------------------------------------------------------
    ; Bootloader: Load the Kernel (Sector 2) from Disk
    ;------------------------------------------------------------------------------

    ;------------------------------------------------------------------------------
    ; Setup buffer location (ES:BX) for disk read
    ; ES:BX = 0x0050:0x0000 → Physical address = 0x0050 * 16 + 0x0000 = 0x0500
    ;------------------------------------------------------------------------------
        mov     ax, 0x050          ; Segment where data will be loaded
        mov     es, ax
        xor     bx, bx              ; Offset = 0x0000 → ES:BX points to 0x0500

    ;------------------------------------------------------------------------------
    ; BIOS Disk Read via Interrupt 13h
    ; Function: AH = 0x02 → Read Sectors
    ;   AL = Number of sectors to read
    ;   CH = Cylinder number (track)
    ;   CL = Sector number (starts from 1)
    ;   DH = Head number
    ;   DL = Drive number (0x00 = floppy A:, 0x80 = first hard drive)
    ;   ES:BX = Buffer address
    ; On return:
    ;   CF = 0 on success, 1 on error
    ;------------------------------------------------------------------------------

        mov     ah, 0x02            ; Function: Read sector(s)
        mov     al, 0x01            ; Number of sectors to read = 1 (just sector 2)
        mov     ch, 0x00            ; Cylinder 0
        mov     cl, 0x02            ; Sector 2
        mov     dh, 0x00            ; Head 0
        mov     dl, 0x00            ; Drive 0 (floppy drive A:)
        int     0x13                ; Call BIOS Disk Service

        jc      error               ; Jump if CF = 1 (error occurred)
        jmp     success             ; Otherwise, continue

error:
    mov     si, loading_error
    call    Print
    jmp     halt

success:
    mov     si, loading_success 
    call    Print
;--------------------------------------------------------------------------
    ; Jump to Kernel Entry Point
    ;--------------------------------------------------------------------------
    ; Option 1: Direct jump (simple, works with your linker script)
    ; jmp     0x00:0x600          ; Physical: 0x500 + 0x100 = 0x600
    
    ; Option 2: Read entry point from ELF header (more flexible)
     mov     eax, [0x500 + 0x18]  ; Read 32-bit entry point at offset 0x18
     jmp     eax                   ; Jump to entry point address

halt:

    jmp     $

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
msg db "Welcome to Zeen OS!",0x0D, 0x0A, 0x00
boot_message db "Loading `Zeen kernal`...", 0x0D, 0x0A, 0x0
loading_error db "Disk read error! Halting system...",0x0D, 0x0A, 0x0
loading_success db "Kernel loaded successfully!...",0x0D, 0x0A, 0x0

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
