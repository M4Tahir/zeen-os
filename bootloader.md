---

```asm
;*********************************************************
; bootloader.asm
; A simple boot loader
;*********************************************************
```

* These lines are **comments** (everything after `;` in assembly is ignored by the assembler).
* Just documentation: filename (`bootloader.asm`) and purpose (a simple boot loader).

---

```asm
org 0x7c00
```

* `org` tells the assembler at what address this code will be **loaded into memory**.
* In x86, the BIOS loads the boot sector to address `0x7C00` in memory, so this sets the base address.

---

```asm
bits 16

```

* Tells the assembler to generate **16-bit real mode code**.
* The CPU starts in 16-bit real mode after boot, so this is necessary.

---

```asm
start: jmp boot
```

* Defines a label `start` and immediately jumps (`jmp`) to the `boot` label.
* Skips over the data (`msg`) so execution doesn’t run into it.

---

```asm
; Const and vairable defination
msg db "Welcome to Zeen OS!", 0ah, 0dh, 0h
```

* Defines a string constant in memory.
* `db` = **define byte**.
* `"Welcome to Zeen OS!"` is the text in ASCII.
* `0ah` = newline (`\n`), `0dh` = carriage return (`\r`), `0h` = string terminator.

---

```asm
boot:
    cli ; no interrup
    cld ; to init
    hlt ; halt the system
```

* `cli` = **Clear Interrupt Flag** → disables hardware interrupts (the CPU won’t respond to them).
* `cld` = **Clear Direction Flag** → ensures string operations increment memory pointers (left-to-right).
* `hlt` = **Halt** → stops CPU execution until the next interrupt occurs.

⚠️ Note: At this point, nothing is shown on screen because there’s no `print` routine — it just halts after disabling interrupts.

---

```asm
; As we have 512 bytes to use and the last 2 bytes are used as signature 0xaa55 so 
; we zero padd the current till the 510 byes and the move the signature int 511 and 512 bytes
```

* Comment explaining that:

  * A boot sector must be **exactly 512 bytes**.
  * The last two bytes (`511` and `512`) must contain the **boot signature** `0xAA55`.

---

```asm
times 510 - ($ - $$) db 0
```

* `times` = assembler directive to repeat something.
* `$` = current address, `$$` = start of the current section (here, `0x7C00`).
* `($ - $$)` = how many bytes we’ve written so far.
* `510 - (...)` = how many bytes remain until 510.
* `db 0` = fill with zeros.
* In short: **fills everything with zeros until offset 510**.

---

```asm
dw 0xAA55 ; boot signature
```

* `dw` = **define word** (2 bytes).
* Writes the boot signature `0xAA55` (little endian, so stored as `55 AA`).
* BIOS checks for this signature to know the sector is bootable.

---

