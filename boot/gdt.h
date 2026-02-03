#ifndef KERNEL_GDT_H
#define KERNEL_GDT_H

#include <stdint.h>

/**
 * @file gdt.h
 * @brief Global Descriptor Table (GDT) definitions and interface
 *
 * This module provides structures and functions for configuring the x86
 * Global Descriptor Table, which defines memory segments and their access
 * permissions in protected mode.
 */

#define GDT_ENTRY_BASE  0x0
#define GDT_ENTRY_LIMIT 0xFFFFFFFF

/**
 *  Global Descriptor Table (GDT) Layout Reference
 * GDT Entry Structure (8 bytes):
 *   Bytes:  7          6              5          4        3       2       1       0
 *        [Base    ][Flags|Lim ][Access ][Base   ][  Base Low   ][  Limit Low  ]
 *        [31:24   ][High  4bit][Byte   ][23:16  ][  15:0       ][  15:0       ]
 *
 * Access Byte (bits 7-0):
 *
 *   Bit:   7     6   5     4     3     2      1     0
 *        ┌───┬──────┬───┬─────┬─────┬────┬─────┬───┐
 *        │ P │  DPL │ S │  E  │ DC  │ RW │  A  │   │
 *        └───┴──────┴───┴─────┴─────┴────┴─────┴───┘
 *
 *   P   = Present (segment is valid)
 *   DPL = Descriptor Privilege Level (0-3: ring 0 = kernel, ring 3 = user)
 *   S   = Descriptor type (0 = system segment, 1 = code/data segment)
 *   E   = Executable bit (1 = code segment, 0 = data segment)
 *   DC  = Direction bit (data) / Conforming bit (code)
 *   RW  = Readable (code) / Writable (data)
 *   A   = Accessed (automatically set by CPU on segment access)
 *
 * Granularity Flags (upper 4 bits of granularity byte):
 *
 *   Bit:   7     6      5     4
 *        ┌───┬──────┬─────┬─────┐
 *        │ G │  DB  │  L  │  0  │
 *        └───┴──────┴─────┴─────┘
 *   G  = Granularity (0 = 1 byte blocks, 1 = 4 KB page blocks)
 *   DB = Size flag (0 = 16-bit protected mode, 1 = 32-bit protected mode)
 *   L  = Long mode (1 = 64-bit code segment, 0 = not 64-bit)
 *   0  = Reserved (must be zero)
 */

//  Access Byte Macros

/** @brief Segment present bit */
#define SEG_PRESENT(x) ((x) << 7)

/** @brief Descriptor privilege level (0 = kernel, 3 = user) */
#define SEG_DPL(x) (((x) & 0x3) << 5)

/** @brief Descriptor type (1 = code/data segment, 0 = system segment) */
#define SEG_TYPE(x) ((x) << 4)

/** @brief Executable segment flag */
#define SEG_EXEC (1 << 3)

/** @brief Conforming bit for code segments */
#define SEG_CONFORMING(x) ((x) << 2)

/** @brief Read/Write permission bit */
#define SEG_RW (1 << 1)

/** @brief Accessed bit (set by CPU) */
#define SEG_ACCESSED (1 << 0)

// Data Segment Type Combinations

#define SEG_DATA_RD     0x0 /**< Read-only */
#define SEG_DATA_RDA    0x1 /**< Read-only, accessed */
#define SEG_DATA_RDRW   0x2 /**< Read/write */
#define SEG_DATA_RDRWA  0x3 /**< Read/write, accessed */
#define SEG_DATA_EXP    0x4 /**< Expand-down */
#define SEG_DATA_EXPA   0x5 /**< Expand-down, accessed */
#define SEG_DATA_EXPRW  0x6 /**< Expand-down, read/write */
#define SEG_DATA_EXPRWA 0x7 /**< Expand-down, read/write, accessed */

// Code Segment Type Combinations

#define SEG_CODE_EX     0x8 /**< Execute-only */
#define SEG_CODE_EXA    0x9 /**< Execute-only, accessed */
#define SEG_CODE_EXRD   0xA /**< Execute/read */
#define SEG_CODE_EXRDA  0xB /**< Execute/read, accessed */
#define SEG_CODE_EXC    0xC /**< Execute-only, conforming */
#define SEG_CODE_EXCA   0xD /**< Execute-only, conforming, accessed */
#define SEG_CODE_EXRDC  0xE /**< Execute/read, conforming */
#define SEG_CODE_EXRDCA 0xF /**< Execute/read, conforming, accessed */

// Granularity Flags

/** @brief Granularity: 1 = 4KB blocks, 0 = byte blocks */
#define GRAN_4K(x) ((x) << 7)

/** @brief Operand size: 1 = 32-bit, 0 = 16-bit */
#define GRAN_32BIT(x) ((x) << 6)

/** @brief Long mode: 1 = 64-bit code segment */
#define GRAN_LONG(x) ((x) << 5)

/** @brief Reserved bit (always 0) */
#define GRAN_RESERVED(x) ((x) << 4)

// GDT Structures

/**
 * @brief GDT entry structure
 *
 * Represents a single 8-byte entry in the Global Descriptor Table.
 * Each entry defines a memory segment's base address, limit, and access rights.
 */
typedef struct gdt_entry {
    uint16_t limit_low; /**< Lower 16 bits of segment limit */
    uint16_t base_low;  /**< Lower 16 bits of base address */
    uint8_t  base_mid;  /**< Middle 8 bits of base address */
    uint8_t  access;    /**< Access byte (present, DPL, type, etc.) */
    uint8_t  gran;      /**< Granularity byte (flags + upper 4 bits of limit) */
    uint8_t  base_high; /**< Upper 8 bits of base address */
} __attribute__((packed)) gdt_entry_t;

/**
 * @brief GDT pointer structure
 *
 * Used by the LGDT instruction to load the GDT into the processor.
 * Points to the start of the GDT and specifies its size.
 */
typedef struct gdt_ptr {
    uint16_t limit; /**< Size of GDT in bytes minus 1 */
    uint32_t base;  /**< Linear address of the first GDT entry */
} __attribute__((packed)) gdt_ptr_t;

extern gdt_entry_t gdt_table[5];
extern gdt_ptr_t   gdt_ptr;

/**
 * @brief Initialize the Global Descriptor Table
 *
 * Sets up the GDT with standard kernel and user mode segments:
 *   - Entry 0: Null descriptor (required by x86 architecture)
 *   - Entry 1: Kernel CODE segment (selector 0x08)
 *   - Entry 2: Kernel DATA segment (selector 0x10)
 *   - Entry 3: User DATA segment (selector 0x18)
 *   - Entry 4: User CODE segment (selector 0x20)
 */
void init_gdt(void);

/**
 * @brief Configure a single GDT entry
 *
 * @param index  Index in the GDT table (0-4)
 * @param base   32-bit linear base address of the segment
 * @param limit  20-bit segment limit (size - 1)
 * @param access Access byte defining segment type and permissions
 * @param gran   Granularity byte containing flags and upper limit bits
 */
void gdt_set_entry(int index, uint32_t base, uint32_t limit, uint8_t access, uint8_t gran);

/**
 * @brief Load the GDT into the processor
 *
 * Uses the LGDT instruction to load the GDT pointer into the GDTR register.
 * This function must be implemented in assembly.
 *
 * @param gdt_ptr_address Address of the gdt_ptr_t structure
 */
extern void gdt_flush(uint32_t gdt_ptr_address);

#endif // KERNEL_GDT_H
