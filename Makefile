BUILD_DIR = ./build

BOOTLOADER = $(BUILD_DIR)/boot/bootloader.o
KERNEL = $(BUILD_DIR)/kernal/kernal
DISK_IMG = $(BUILD_DIR)/disk.img

all: bootdisk

bootloader:
	$(MAKE) -C boot

kernal:
	$(MAKE) -C kernal

bootdisk: bootloader kernal
	@echo "Creating floppy disk image..."
	dd if=/dev/zero of=$(DISK_IMG) bs=512 count=2880
	dd conv=notrunc if=$(BOOTLOADER) of=$(DISK_IMG) bs=512 count=1 seek=0
	KERNEL_SECTORS=$$(expr $$(stat --printf="%s" $(KERNEL)) / 512); \
	dd conv=notrunc if=$(KERNEL) of=$(DISK_IMG) bs=512 count=$$KERNEL_SECTORS seek=1
	@echo "Disk image ready at $(DISK_IMG)"

qemu: bootdisk
	qemu-system-i386 -drive format=raw,file=$(DISK_IMG),if=floppy -display gtk

qemu-debug: bootdisk
	qemu-system-i386 -drive format=raw,file=$(DISK_IMG),if=floppy -display gtk -gdb tcp::26000 -S

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all bootloader kernal bootdisk qemu qemu-debug clean
