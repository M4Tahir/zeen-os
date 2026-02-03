# ==========================================================
# Zeen OS - GDB Configuration File (.gdbinit)
# ----------------------------------------------------------
# This file automates the debugging setup for the bootloader
# and kernel when using QEMU + GDB.# ==========================================================


# By default, GDB shows AT&T syntax (e.g., mov %ax, %bx),Order
# Inter: dest, src, AT&T: src, dest
# which is harder to read. This switches to Intel syntax
set disassembly-flavor intel

layout asm
layout reg


set architecture i8086


# QEMU should be launched with:
#   qemu-system-i386 -S -gdb tcp::26000 -drive file=disk.img,format=raw
# The '-S' flag pauses the CPU, and this line connects GDB
# to the waiting QEMU instance.
target remote localhost:26000

# Load symbols from ELF
symbol-file build/kernal/kernal
add-symbol-file build/kernal/kernal 0x10000

# BIOS loads the bootloader to physical address 0x7C00.
# This ensures GDB stops execution right when the bootloader
# starts running.
b *0x7C00


# ----------------------------------------------------------
# 6. Define hook-stop: custom function triggered on stop
# ----------------------------------------------------------
# 'hook-stop' is a GDB built-in hook that executes whenever
# the program stops (after a breakpoint or step).
#
# This one prints:
#   - The current segment:offset (CS:IP)
#   - The next instruction at that address
#
# Formula for physical address in real mode:
#   physical = segment * 16 + offset
# ----------------------------------------------------------
define hook-stop
    printf "[%04x:%04x] ", $cs, $eip
    x/i $cs*16+$eip
end


echo "Zeen OS GDB environment loaded successfully!\n"
