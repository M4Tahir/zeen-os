#ifndef KERNAL_GDT_H
#define KERNAL_GDT_H

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

#define SEL_PRESENT(x)    ((x) << 0x7)       // 0x80 1 valid and 0 invalid
#define SEL_PRIVLAGE(x)   ((x & 0x3) << 0x5) // 0x0(ring 0) 0x1(ring 1),0x2(ring 2), 0x3( ring 3 user)
#define SEL_DESCRIPTOR(x) ((x) << 0x4)       // 1 0x8 code/data, 0 sys seg
#define SEL_

#endif // KERNAL_GDT_H
