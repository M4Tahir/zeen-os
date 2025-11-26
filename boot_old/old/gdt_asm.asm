; gdt.asm

; Export the symbol so the C linker can see it.
global gdt_flush

gdt_flush:
    ; The C function passes the pointer to the GDT descriptor as the first argument.
    ; On 32-bit cdecl ABI, arguments are pushed on the stack.
    ; [esp + 4] = first function argument = pointer to struct gdt_ptr.
    mov eax, [esp + 4]

    ; lgdt expects a memory operand containing the 6-byte GDT descriptor:
    ;   uint16_t limit;
    ;   uint32_t base;
    lgdt [eax]

    ; ------------------------------------------------------------
    ; Reloading segment registers after installing a new GDT
    ; ------------------------------------------------------------
    ; Loading the GDT alone does NOT make the CPU use the new descriptors.
    ; You must explicitly reload all segment registers with valid selectors.
    ;
    ; A segment selector is:
    ;   index * 8 (each descriptor is 8 bytes)
    ;
    ; In our GDT:
    ;   index 2 = kernel data segment
    ;   selector = 2 * 8 = 16 = 0x10
    ;
    ; So we load 0x10 into all data-segment registers.

    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; ------------------------------------------------------------
    ; Reloading CS (Code Segment)
    ; ------------------------------------------------------------
    ; CS cannot be loaded with MOV.
    ; The only way to update CS is through a far jump (jmp selector:offset).
    ;
    ; The kernel code segment is at:
    ;   index 1   => selector = 1 * 8 = 0x08
    ;
    ; So we perform a far jump to 0x08:.flush,
    ; which reloads CS with the kernel code segment selector.
    ;
    ; After the jump, execution continues at the label `.flush`,
    ; now running with the new code segment.
    jmp 0x08:.flush

.flush:
    ; Return to the C function (init_gdt)
    ret
