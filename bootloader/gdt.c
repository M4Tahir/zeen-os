
// 0 -> systec segment 1 code or data segmend. i.e its part of access byte so
// its structure is
// Bit: 7   6   5   4   3   2   1   0
//      P  DPL DPL S  Type  Type  Type  Type
// our of the 64 bit we need to change the byte b/w bit 40-47 or byte number 5
// and we that byte we need to chagne the 43 bit or the last bit of the 5the
// fifth byte
// (0000 0001) << 4 = 0000 1000 -> we have set the seg desctyupe
#define SEG_DESCTYPE(x) ((x) << 0x04)
#define SEG_PRES(x) ((x) << 0x07)
#define SEG_PRIV(x) ((x & 0x03) << 0x05) // 0 ring 0, 11 ring 3

// FLags
#define SEG_GRAN(x) ((x << 0x07)) // set = 4kb closed = 1 byte
#define SEG_SIZE(x) ((x) << 0x06) // set = 32 bit mode and closed = 16 bit mide
#define SEG_LONG(x) ((x) << 0x05) // set = 64 bit codek
#define SEG_SVAL(x) \
	((x) << 0x04) // // avl (this has mening to os, cpu don't use it)

// Access byte 5 bit nubmer 0-3 0100-1111 reserved
// Data segment (s=1, code/data)
#define SEG_DATA_RD 0x00 // Read only
#define SEG_DATA_RDA 0x01 // Read only accessed
#define SEG_DATA_RDRW 0x02 // read write
#define SEG_DATA_RDRWA 0x03 // read write accessed

// Code segment s =1 code/ata 1000-1111
#define SEG_CODE_EX 0x08 // execute only
#define SEG_CODE_EXA 0x09 // execute only accessed
#define SEG_CODE_EXRD 0x0A // execure read
#define SEG_CODE_EXRDA 0x0B // execure read accessed
#define SEG_CODE_EXC 0x0C // execure  conforming
#define SEG_CODE_EXCA 0x0D // execure  accessed conforming
#define SEG_CODE_EXRDC 0x0E // execure read  conforming
#define SEG_CODE_EXRDCA 0x0F // execure read  conforming accessed

// As the GDT has null, kernal code data use code data and taskstate segment.
// Task state segment is need when you want auto stack siwthc on privlage cahnge
// ring 3 -> ring 0 then it load the kearnal dedicated kearnla stack so, user
// progrma are safely seperate form kearnl stack. if don't use then we cna use
// simply iret for this prupose.

#define GDT_CODE_PL0
#define GDT_DATA_PL0
#define GDT_CODE_PL3
#define GDT_DATA_PL3
#define GDT_NULL

typedef struct {
	// base = 32 bits, limit = 20 bit, access = 1 byte, flags = 1 byte
	// access: P => 1 bit, DPL => 2 bit field (ring level), S => 1 bit (set
	// code or data segment, s not set system segment), Type => 4 bits
	// (indicate rwx)
	unsigned long limit, base, access, flags;

} gdt_entry_t;

void init_gdt() {
	gdt_entry_t gdt_table[3];

	// Null Descirptor
	gdt_table[0].base = 0;
	gdt_table[0].limit = 0;
	gdt_table[0].access = 0;
	gdt_table[0].flags = 0;

	//  Descirptor
	gdt_table[1].base = 0;
	gdt_table[1].limit = 0xfffff;
	// code bit + ring0 + present bit
	gdt_table[1].access = 9;

	gdt_table[1].flags = 0;
}
