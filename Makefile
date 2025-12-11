BUILD_DIR = ./build
BOOTLOADER := $(BUILD_DIR)/boot/boot.bin
STAGE2 := $(BUILD_DIR)/boot/stage2-boot.bin
KERNEL := $(BUILD_DIR)/kernel/kernel
DISK_IMG := $(BUILD_DIR)/disk.img
DISK_SIZE_MB := 10

all: bootdisk

bootloader:
	$(MAKE) -C boot

kernel:
	$(MAKE) -C kernel

# # 2>/dev/null : hide error message
# Calculate disk layout
define CALC_LAYOUT
	$(eval STAGE2_SIZE := $(shell stat --printf="%s" $(STAGE2) 2>/dev/null || echo 0))
	$(eval STAGE2_SECTORS := $(shell echo $$(( ($(STAGE2_SIZE) + 511) / 512 ))))
	$(eval STAGE2_END_SECTOR := $(STAGE2_SECTORS))
	$(eval KERNEL_START_SECTOR := $(shell echo $$(( 1 + $(STAGE2_SECTORS) ))))
	$(eval KERNEL_SIZE := $(shell stat --printf="%s" $(KERNEL) 2>/dev/null || echo 0))
	$(eval KERNEL_SECTORS := $(shell echo $$(( ($(KERNEL_SIZE) + 511) / 512 ))))
	$(eval KERNEL_END_SECTOR := $(shell echo $$(( $(KERNEL_START_SECTOR) + $(KERNEL_SECTORS) - 1 ))))
endef

# bs: block size, count: number of blocks to write
bootdisk: bootloader kernel
	@echo "Creating disk image..."
	@dd if=/dev/zero of=$(DISK_IMG) bs=512 count=$$(expr $(DISK_SIZE_MB) \* 1024 \* 1024 / 512) 2>/dev/null
	
	@echo "Writing Stage 1 bootloader (sector 0)..."
	@dd conv=notrunc if=$(BOOTLOADER) of=$(DISK_IMG) bs=512 count=1 seek=0 2>/dev/null
	
	$(CALC_LAYOUT)
	@echo "Stage 2 size: $(STAGE2_SIZE) bytes ($(STAGE2_SECTORS) sectors)"
	@echo "Writing Stage 2 bootloader (sectors 1-$(STAGE2_END_SECTOR))..."
	@dd conv=notrunc if=$(STAGE2) of=$(DISK_IMG) bs=512 seek=1 2>/dev/null
	
	@echo "Kernel size: $(KERNEL_SIZE) bytes ($(KERNEL_SECTORS) sectors)"
	@echo "Writing kernel (sectors $(KERNEL_START_SECTOR)-$(KERNEL_END_SECTOR))..."
	@dd conv=notrunc if=$(KERNEL) of=$(DISK_IMG) bs=512 seek=$(KERNEL_START_SECTOR) 2>/dev/null
	
	@echo ""
	@echo "=== Disk Layout ==="
	@echo "Sector 0:                    Stage 1 (boot sector)"
	@echo "Sectors 1-$(STAGE2_END_SECTOR):                Stage 2 bootloader"
	@echo "Sectors $(KERNEL_START_SECTOR)-$(KERNEL_END_SECTOR):          Kernel"
	@echo ""
	@echo "Disk image ready at $(DISK_IMG)"

qemu: bootdisk
	qemu-system-i386 -hda $(DISK_IMG) -display gtk

qemu-debug: bootdisk
	qemu-system-i386 -hda $(DISK_IMG) -display gtk -gdb tcp::26000 -S

clean:
	rm -rf $(BUILD_DIR)
	$(MAKE) -C boot clean
	$(MAKE) -C kernel clean

.PHONY: all bootloader kernel bootdisk qemu qemu-debug clean
