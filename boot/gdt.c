#include "gdt.h"

gdt_entry_t gdt_table[5];
gdt_ptr_t   gdt_ptr;

void init_gdt(void)
{
    /* Entry 0: Null descriptor - required by x86 architecture */
    gdt_set_entry(0, 0, 0, 0, 0);

    /* Entry 1: Kernel data segment (ring 0) */
    gdt_set_entry(1, GDT_ENTRY_BASE, GDT_ENTRY_LIMIT,
                  SEG_PRESENT(1) | SEG_DPL(0) | SEG_TYPE(1) | SEG_DATA_RDRWA,
                  GRAN_4K(1) | GRAN_32BIT(1) | GRAN_LONG(0));

    /* Entry 2: Kernel code segment (ring 0) */
    gdt_set_entry(2, GDT_ENTRY_BASE, GDT_ENTRY_LIMIT,
                  SEG_PRESENT(1) | SEG_DPL(0) | SEG_TYPE(1) | SEG_CODE_EXRDCA,
                  GRAN_4K(1) | GRAN_32BIT(1) | GRAN_LONG(0));

    /* Entry 3: User data segment (ring 3) */
    gdt_set_entry(3, GDT_ENTRY_BASE, GDT_ENTRY_LIMIT,
                  SEG_PRESENT(1) | SEG_DPL(0x3) | SEG_TYPE(1) | SEG_DATA_RDA,
                  GRAN_4K(1) | GRAN_32BIT(1) | GRAN_LONG(0));

    /* Entry 4: User code segment (ring 3) */
    gdt_set_entry(4, GDT_ENTRY_BASE, GDT_ENTRY_LIMIT,
                  SEG_PRESENT(1) | SEG_DPL(0x3) | SEG_TYPE(1) | SEG_CODE_EXRDCA,
                  GRAN_4K(1) | GRAN_32BIT(1) | GRAN_LONG(0));

    /* TODO: Add Task State Segment (TSS) entries for hardware task switching */
}

/**
 * @brief Configure a single GDT entry
 *
 * Populates a GDT entry with the specified base address, limit, and flags.
 * The 8-byte GDT entry is constructed from non-contiguous fields:
 *
 * Byte Layout:
 *   Bytes 0-1: Limit (bits 0-15)
 *   Bytes 2-3: Base (bits 0-15)
 *   Byte  4:   Base (bits 16-23)
 *   Byte  5:   Access byte
 *   Byte  6:   Granularity flags (bits 4-7) + Limit (bits 16-19)
 *   Byte  7:   Base (bits 24-31)
 *
 * @param index  GDT table index (0-4)
 * @param base   32-bit linear base address
 * @param limit  20-bit limit value (maximum offset within segment)
 * @param access Access byte (present, privilege, type, permissions)
 * @param gran   Granularity and flags byte
 */
void gdt_set_entry(int index, uint32_t base, uint32_t limit, uint8_t access, uint8_t gran)
{
    /* Set the lower 16 bits of the segment limit */
    gdt_table[index].limit_low = limit & 0xFFFF;

    /* Set the lower 16 bits of the base address */
    gdt_table[index].base_low = base & 0xFFFF;

    /* Set the middle 8 bits of the base address (bits 16-23) */
    gdt_table[index].base_mid = (base >> 16) & 0xFF;

    /* Set the upper 8 bits of the base address (bits 24-31) */
    gdt_table[index].base_high = (base >> 24) & 0xFF;

    /* Set the access byte (present, DPL, type, permissions) */
    gdt_table[index].access = access;

    /*
     * Set the granularity byte:
     *   - Lower 4 bits: upper 4 bits of the 20-bit limit (bits 16-19)
     *   - Upper 4 bits: flags (granularity, size, long mode)
     */
    gdt_table[index].gran = ((limit >> 16) & 0x0F) | (gran & 0xF0);
}
