;==============================================================================
; bootloader.asm - Main bootloader file
;==============================================================================
[bits 16]
global start


KERNEL_SEG equ 0x1000
KERNEL_OFF equ 0x0000                ; Load kernal at addrss 64kb (0x1000*16+0x00 = 0x10000)
KERNEL_SECT equ 32                   ; read 32 secotors
KERNEL_LBA equ 2                     ; starting sector

STACK_TOP equ 0x90000                ; Top of stack 0x90000 (576kb)
STACK_BOTTOM equ 0x80000             ; Bottom of stack 64kb of stack.(not used just for rem)

start:
    jmp boot

;------------------------------------------------------------------------------
; Data Section
;------------------------------------------------------------------------------
msg             db "Zeen OS", 0x0D, 0x0A, 0
boot_message    db "Load...", 0x0D, 0x0A, 0
loading_error   db "Disk err", 0x0D, 0x0A, 0
loading_success db "OK!", 0x0D, 0x0A, 0

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
    mov ax, STACK_TOP >> 4     ; 0x90000/16 = 0x9000     
    mov ss, ax
    mov sp, 0x0000

    sti                         ; enable interrupts

    call ClearScreen

    mov si, msg
    call Print

    mov si, boot_message
    call Print

    call load_kernal

    jmp KERNEL_SEG:KERNEL_OFF   ; long jum segment:offset or we can use cs:ip (if we don't specify offset here)

; load_kernel - uses INT 13h extension AH=0x42 (LBA)
; Disk Address Packet (DAP) layout (16 bytes):
; offset 0: size (1 byte, 0x10)
; offset 1: reserved (1 byte, 0x00)
; offset 2: word: number of sectors to transfer
; offset 4: word: buffer offset
; offset 6: word: buffer segment
; offset 8: qword: starting LBA (little endian)
load_kernal:
    ; fill dap in memory
    lea si, [dap]                 ; ds:si -> dap ds = 0x00

    xor bx, bx
    mov dl, 0x80                ; first hard disk
    mov ah, 0x42                ; extend read support 
    int 0x13

    jc disk_error
    ret

; DAP(disk address packet) must be 16-byte structure
dap:
    db 0x10                       ; size = 16 bytes
    db 0x00                       ; reserved
    dw KERNEL_SECT                ; number of sectors to read (word)
    dw KERNEL_OFF                 ; offset of buffer (word)
    dw KERNEL_SEG                 ; segment of buffer (word)
    dq KERNEL_LBA                 ; starting LBA (qword, little-endian)

disk_error:
    mov si, loading_error
    call Print
    jmp $


;------------------------------------------------------------------------------
; Include external files
;------------------------------------------------------------------------------
%include "io.asm"

;------------------------------------------------------------------------------
; Boot Signature
;------------------------------------------------------------------------------
times 510 - ($ - $$) db 0
dw 0xAA55

