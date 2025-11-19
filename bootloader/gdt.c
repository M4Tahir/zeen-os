// Note: it's part of compiler intrinsice header so we can use it in free standing.
#include <stdint.h>
/*
// Access
// Bit:  7    6  5    4    3    2    1    0
//      ┌───┬────────┬───┬───┬────┬────┬───┐
//      │ P │  DPL   │ S │ E │ DC │ RW │ A │
//      └───┴────────┴───┴───┴────┴────┴───┘
// Flags
// Bit:  3    2    1    0
//      ┌───┬────┬───┬──────┐
//      │ G │ DB │ L │ Rsv  │
//      └───┴────┴───┴──────┘

// Access byte: total 8 bits
#define SEG_PRESENT(x)    (x << 0x07)          // 0x80 seg valid (1) invalid (0)
#define SEG_PRIVILEGE(x)  ((x & 0x03) << 0x05) // 0x0, 0x20, 0x40, 0x060 Ring 0,1,2,3
#define SEG_DESCRIPTOR(x) (x << 0x04)          // 0x08 1 code/data seg, 0 sys seg (tss, ldt, gates)
#define SEG_EXEC(x)       (x << 0x03)          // 0x04 1 executable, 0 mean none
#define SEG_CONFORMING(x) (x << 0x02)          // 0x02 0: stack grow up, 1 stack grow down

#define SEG_DATA_RD        0x00 // Read-Only
#define SEG_DATA_RDA       0x01 // Read-Only, accessed
#define SEG_DATA_RDWR      0x02 // Read/Write
#define SEG_DATA_RDWRA     0x03 // Read/Write, accessed
#define SEG_DATA_RDEXPD    0x04 // Read-Only, expand-down
#define SEG_DATA_RDEXPDA   0x05 // Read-Only, expand-down, accessed
#define SEG_DATA_RDWREXPD  0x06 // Read/Write, expand-down
#define SEG_DATA_RDWREXPDA 0x07 // Read/Write, expand-down, accessed
#define SEG_CODE_EX        0x08 // Execute-Only
#define SEG_CODE_EXA       0x09 // Execute-Only, accessed
#define SEG_CODE_EXRD      0x0A // Execute/Read
#define SEG_CODE_EXRDA     0x0B // Execute/Read, accessed
#define SEG_CODE_EXC       0x0C // Execute-Only, conforming
#define SEG_CODE_EXCA      0x0D // Execute-Only, conforming, accessed
#define SEG_CODE_EXRDC     0x0E // Execute/Read, conforming
#define SEG_CODE_EXRDCA    0x0F // Execute/Read, conforming, accessed

// Flags higher 4 bits of byte 6
#define SEG_GRANULARITY(x) (x << 0x07) // 0x80 0: mean 1byte, 1 mean 4kb pages
#define SEG_SIZE_FLAG(x)   (x << 0x06) // 0x0 0: 16 bit protected mode, 1 mean 32 bit pm
#define SEG_LONG_MODE(x)   (x << 0x05)
#define SEG_RESERVED(x)    (x << 0x04) // Fixed: Shift 4 for AVL bit, Shift 0 overlaps with Limit

#define BASE      0x0
#define LIMIT_MAX 0xFFFFF // Fixed: Limit is 20 bits (0xFFFFF), not 24 bits (0xFFFFFF)

// | Limit 0:15 | Base low 0:15 | Base mid 16:23 | Access | Flags | Base high 24:31 |
// __attribute__((packed)) ensure that compiler don't add padding
typedef struct {
    uint16_t limit_low;
    uint16_t base_low;
    uint8_t  base_mid;
    uint8_t  access;
    uint8_t  gran; // flags + limit high 4 + 4 bits
    uint8_t  base_high;

} __attribute__((packed)) gdt_entry_t;

typedef struct {
    uint16_t limit;
    uint32_t base;
} __attribute__((packed)) gdt_ptr_t;

gdt_entry_t gdt_table[5];
gdt_ptr_t   gdt_ptr;

void gdt_set_entry(int i, uint32_t base, uint32_t limit, uint8_t access, uint8_t gran)
{
    gdt_table[i].base_low  = (base & 0xFFFF);
    gdt_table[i].base_mid  = (base >> 16) & 0xFF;
    gdt_table[i].base_high = (base >> 24) & 0xFF;

    gdt_table[i].limit_low = (limit & 0xFFFF);
    gdt_table[i].access    = access;

    // Granularity = High nibble of Limit + Flags
    // Take top 4 bits of limit (bits 16-19)
    // Combine with the flags (top 4 bits of gran arg)
    gdt_table[i].gran = (limit >> 16) & 0x0F;
    gdt_table[i].gran |= (gran & 0xF0);
}

void init_gdt()
{
    // Null Descriptor
    gdt_set_entry(0, 0, 0, 0, 0);

    // Kernel Code Segment
    gdt_set_entry(1, BASE, LIMIT_MAX,
                  SEG_PRESENT(1) | SEG_PRIVILEGE(0) | SEG_DESCRIPTOR(1) | SEG_EXEC(1) |
                      SEG_CODE_EXRD,
                  SEG_GRANULARITY(1) | SEG_SIZE_FLAG(1) | SEG_LONG_MODE(0) | SEG_RESERVED(0));

    // Kernel Data Segment
    gdt_set_entry(2, BASE, LIMIT_MAX,
                  SEG_PRESENT(1) | SEG_PRIVILEGE(0) | SEG_DESCRIPTOR(1) | SEG_EXEC(0) |
                      SEG_DATA_RDWR,
                  SEG_GRANULARITY(1) | SEG_SIZE_FLAG(1) | SEG_LONG_MODE(0) | SEG_RESERVED(0));

    // User Code Segment
    gdt_set_entry(3, BASE, LIMIT_MAX,
                  SEG_PRESENT(1) | SEG_PRIVILEGE(3) | SEG_DESCRIPTOR(1) | SEG_EXEC(1) |
                      SEG_CODE_EXRD,
                  SEG_GRANULARITY(1) | SEG_SIZE_FLAG(1) | SEG_LONG_MODE(0) | SEG_RESERVED(0));
}
*/

// Internal Shift Macros
#define SEG_PRESENT(x)    ((x) << 0x07)          // P: Present
#define SEG_PRIVILEGE(x)  (((x) & 0x03) << 0x05) // DPL: Ring 0-3
#define SEG_DESCRIPTOR(x) ((x) << 0x04)          // S: 1=Code/Data, 0=System
#define SEG_EXEC(x)       ((x) << 0x03)          // E: Executable
#define SEG_RW(x)         ((x) << 0x01)          // RW: Readable (Code) or Writable (Data)

// Common Access Byte Configurations
// Kernel Code: Present, Ring 0, Code/Data, Executable, Readable
#define GDT_ACCESS_KERNEL_CODE (0x9A)
// Kernel Data: Present, Ring 0, Code/Data, Not Executable, Writable
#define GDT_ACCESS_KERNEL_DATA (0x92)
// User Code:   Present, Ring 3, Code/Data, Executable, Readable
#define GDT_ACCESS_USER_CODE (0xFA)
// User Data:   Present, Ring 3, Code/Data, Not Executable, Writable
#define GDT_ACCESS_USER_DATA (0xF2)

// Flags (Granularity) Macros
#define SEG_GRAN_PAGE (1 << 7) // G: 1=4KB blocks, 0=1 byte blocks
#define SEG_SIZE_32   (1 << 6) // DB: 1=32-bit, 0=16-bit
#define SEG_LONG_MODE (1 << 5) // L: 1=64-bit mode
#define SEG_AVAIL     (0 << 4) // AVL: Available for software use

// Common Flags: 4KB Granularity, 32-bit Protected Mode
#define GDT_FLAG_32BIT (SEG_GRAN_PAGE | SEG_SIZE_32)

#define BASE_DEFAULT 0x00000000
#define LIMIT_4GB    0xFFFFF // 20 bits. With 4KB Granularity = 4GB

// Packed to ensure exact binary layout for the CPU
typedef struct {
    uint16_t limit_low;
    uint16_t base_low;
    uint8_t  base_mid;
    uint8_t  access;
    uint8_t  granularity;
    uint8_t  base_high;
} __attribute__((packed)) gdt_entry_t;

typedef struct {
    uint16_t limit;
    uint32_t base;
} __attribute__((packed)) gdt_ptr_t;

gdt_entry_t gdt_table[5];
gdt_ptr_t   gdt_ptr;

void gdt_set_entry(int i, uint32_t base, uint32_t limit, uint8_t access, uint8_t flags)
{
    gdt_table[i].base_low  = (base & 0xFFFF);
    gdt_table[i].base_mid  = (base >> 16) & 0xFF;
    gdt_table[i].base_high = (base >> 24) & 0xFF;

    gdt_table[i].limit_low = (limit & 0xFFFF);
    gdt_table[i].access    = access;

    // Combine the top 4 bits of the Limit with the Flags
    // Limit is 20 bits. We need bits 16-19.
    gdt_table[i].granularity = (limit >> 16) & 0x0F;
    gdt_table[i].granularity |= (flags & 0xF0);
}

/**
 * The address of the GDT is required by the LGDT register, so we have to use assembly to access
 * LGDT register and then put the passed address to it in assembly.
 * */
extern void gdt_flush(uint32_t gdt_ptr_address);

void init_gdt()
{
    // 0. Null Descriptor (Required by CPU)
    gdt_set_entry(0, 0, 0, 0, 0);

    // 1. Kernel Code
    gdt_set_entry(1, BASE_DEFAULT, LIMIT_4GB, GDT_ACCESS_KERNEL_CODE, GDT_FLAG_32BIT);

    // 2. Kernel Data
    gdt_set_entry(2, BASE_DEFAULT, LIMIT_4GB, GDT_ACCESS_KERNEL_DATA, GDT_FLAG_32BIT);

    // 3. User Code (Ring 3)
    gdt_set_entry(3, BASE_DEFAULT, LIMIT_4GB, GDT_ACCESS_USER_CODE, GDT_FLAG_32BIT);

    // 4. User Data (Ring 3)
    gdt_set_entry(4, BASE_DEFAULT, LIMIT_4GB, GDT_ACCESS_USER_DATA, GDT_FLAG_32BIT);

    // The "Limit" tells the CPU the address of the very last valid byte in the table, relative to
    // the start.
    // The "Base" is simply the starting memory address of your array.
    gdt_ptr.limit = sizeof(gdt_entry_t) * 5 - 1;
    gdt_ptr.base  = (uint32_t)&gdt_table;

    // Passing the address of the table for the GDTR reg so assembly uses it and put it into the
    // GDTR reg.
    gdt_flush((uint32_t)&gdt_ptr);
}
