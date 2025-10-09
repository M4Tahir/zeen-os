
# Bin dir
BIN_DIR = ../bin

# Files
BOOTLOADER_SRC = bootloader.asm
BOOTLOADER_BIN = $(BIN_DIR)/bootloader
DISK_IMG	   = $(BIN_DIR)/disk.img

ASM = nasm
QEMU = qemu-system-i386

all: $(DISK_IMG)

#  “To build ../bin/bootloader, you need bootloader.asm.”
#$(ASM) = nasm (set at the top of the Makefile).
# -f bin = assemble as flat binary.
# $< = the first dependency (here: bootloader.asm).
# -o $@ = write output to the target file (here: ../bin/bootloader).
# Step 1: assemble bootloader
# $(BOOTLOADER_BIN): $(BOOTLOADER_SRC)
#	 $(ASM) -f bin bootloader.asm -o ../bin/bootloader
# Shotcut
$(BOOTLOADER_BIN): $(BOOTLOADER_SRC)
		$(ASM) -f bin $< -o $@


$(DISK_IMG): $(BOOTLOADER_BIN)
	dd if=/dev/zero of=$(DISK_IMG) bs=512 count=2880
	dd conv=notrunc if=$(BOOTLOADER_BIN) of=$(DISK_IMG) bs=512 count=1 seek=0

# Use gdb to run
debug-run: $(DISK_IMG)
		   $(QEMU) -drive format=raw,file=../bin/disk.img,if=floppy -display gtk -gdb tcp::26000 -S

# Direct run
run: $(DISK_IMG)
		   $(QEMU) -drive format=raw,file=../bin/disk.img,if=floppy -display gtk

build: clean run

clean: 
	rm -f $(BOOTLOADER_BIN) $(DISK_IMG)

.PHONY: all run clean
