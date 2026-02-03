#include "gdt.h"
#include <stdint.h>

gdt_entry_t gdt_table[5];
gdt_ptr_t   gdt_ptr;

void init_gdt(void)
{
    /* Entry 0: Null descriptor - required by x86 architecture */
    gdt_set_entry(0, 0, 0, 0, 0);

    /* Entry 1: Kernel CODE segment (ring 0) - selector 0x08 */
    gdt_set_entry(1, GDT_ENTRY_BASE, GDT_ENTRY_LIMIT,
                  SEG_PRESENT(1) | SEG_DPL(0) | SEG_TYPE(1) | SEG_CODE_EXRD,
                  GRAN_4K(1) | GRAN_32BIT(1) | GRAN_LONG(0));

    /* Entry 2: Kernel DATA segment (ring 0) - selector 0x10 */
    gdt_set_entry(2, GDT_ENTRY_BASE, GDT_ENTRY_LIMIT,
                  SEG_PRESENT(1) | SEG_DPL(0) | SEG_TYPE(1) | SEG_DATA_RDRW,
                  GRAN_4K(1) | GRAN_32BIT(1) | GRAN_LONG(0));

    /* Entry 3: User DATA segment (ring 3) - selector 0x18 */
    gdt_set_entry(3, GDT_ENTRY_BASE, GDT_ENTRY_LIMIT,
                  SEG_PRESENT(1) | SEG_DPL(0x3) | SEG_TYPE(1) | SEG_DATA_RDRW,
                  GRAN_4K(1) | GRAN_32BIT(1) | GRAN_LONG(0));

    /* Entry 4: User CODE segment (ring 3) - selector 0x20 */
    gdt_set_entry(4, GDT_ENTRY_BASE, GDT_ENTRY_LIMIT,
                  SEG_PRESENT(1) | SEG_DPL(0x3) | SEG_TYPE(1) | SEG_CODE_EXRD,
                  GRAN_4K(1) | GRAN_32BIT(1) | GRAN_LONG(0));

    /* TODO: Add Task State Segment (TSS) entries for hardware task switching */

    gdt_ptr.limit = (sizeof(gdt_entry_t) * 5) - 1;
    gdt_ptr.base  = (uint32_t)(&gdt_table);

    gdt_flush((uint32_t)(&gdt_ptr));
}

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
