
// Note: it's part of compiler intrinsice header so we can use it in free
// standing.
#include <stdint.h>
// Access
// Bit:  7    6  5    4    3    2    1    0
//     ┌───┬────────┬───┬───┬────┬────┬───┐
//     │ P │  DPL   │ S │ E │ DC │ RW │ A │
//     └───┴────────┴───┴───┴────┴────┴───┘
// Flags
// Bit:  3    2    1    0
//     ┌───┬────┬───┬──────┐
//     │ G │ DB │ L │ Rsv  │
//     └───┴────┴───┴──────┘

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

// | Limit 0:15 | Base 0:15 | Base 16:23 | Access | Flags | Base 24:31 |
// __attribute__((packed)) ensure that compiler don't add padding
typedef struct {
	uint16_t limit_low;
	uint16_t base_low;
	uint16_t base_middle;
	uint8_t  access;
	uint8_t  flags;
	uint16_t base_high;

} __attribute__((packed)) gdt_entry_t;

typedef struct {
	uint16_t limit;
	uint32_t base;
} __attribute__((packed)) gdt_ptr_t;

gdt_entry_t gdt_table[3];
gdt_ptr_t   gdt_ptr;

void gdt_set_entry(int i, uint32_t base, uint32_t limit, uint8_t access,
                   uint8_t flags)
{
}

void init_gdt()
{
}
