BUILD_DIR := ../build/boot

ASM_SRCS := $(wildcard *.asm)
OBJS := $(patsubst %.asm,$(BUILD_DIR)/%.o,$(ASM_SRCS))
ELFS := $(patsubst %.asm,$(BUILD_DIR)/%.elf,$(ASM_SRCS))

LDSCRIPT := boot.lds

all: $(BUILD_DIR)/boot.bin

# Assemble: .asm → .o    (include DWARF debug info)
$(BUILD_DIR)/%.o: %.asm | $(BUILD_DIR)
	@echo "Assembling $<..."
	nasm -f elf $< -F dwarf -g -o $@
	@echo "Done: $@"

# Per-file ELF for debugging: .o → .elf
$(BUILD_DIR)/%.elf: $(BUILD_DIR)/%.o
	@echo "Creating debug ELF for $<..."
	ld -m elf_i386 -o $@ $<
	@echo "Done: $@"

# Link ALL objects → boot.elf → boot.bin
$(BUILD_DIR)/boot.bin: $(OBJS)
	@echo "Linking bootloader..."
	ld -m elf_i386 -T $(LDSCRIPT) $(OBJS) -o $(BUILD_DIR)/boot.elf
	@echo "Creating flat binary..."
	objcopy -O binary $(BUILD_DIR)/boot.elf $@
	@echo "Bootloader ready: $@"

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean

