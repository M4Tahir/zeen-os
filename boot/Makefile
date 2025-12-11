BUILD_DIR := ../build/boot
ASM_SRCS := $(wildcard *.asm)
OBJS := $(patsubst %.asm,$(BUILD_DIR)/%.o,$(ASM_SRCS))
S1_LDSCRIPT := boot.lds
S1_BIN := $(BUILD_DIR)/boot.bin
S1_ELF := $(BUILD_DIR)/boot.elf
S2_LDSCRIPT := stage2.lds
S2_BIN := $(BUILD_DIR)/stage2-boot.bin
S2_ELF := $(BUILD_DIR)/stage2-boot.elf
S2_START_OFFSET := ./stage2-start-offset.inc

# Default target: ensure .inc exists first, then build everything
all: init_inc $(S1_BIN) $(S2_BIN)

# Initialize .inc file if it doesn't exist (creates a dummy)
init_inc:
	@if [ ! -f $(S2_START_OFFSET) ]; then \
		echo "Creating initial dummy offset file..."; \
		echo "S2_START_OFFSET equ 0x0000" > $(S2_START_OFFSET); \
	fi

# Assemble: .asm → .o (with debug info)
# Now depends on init_inc to ensure .inc exists
$(BUILD_DIR)/%.o: %.asm init_inc | $(BUILD_DIR)
	@echo "Assembling $<..."
	nasm -f elf $< -F dwarf -g -o $@
	@echo "Done: $@"

# Per-file ELF for debugging
$(BUILD_DIR)/%.elf: $(BUILD_DIR)/%.o
	@echo "Creating debug ELF for $<..."
	ld -m elf_i386 -o $@ $
	@echo "Done: $@"

# Stage 1 bootloader
$(S1_BIN): $(BUILD_DIR)/boot.o
	@echo "Linking stage 1 bootloader..."
	ld -m elf_i386 -T $(S1_LDSCRIPT) $(BUILD_DIR)/boot.o -o $(S1_ELF)	
	objcopy -O binary $(S1_ELF) $@
	@echo "Bootloader ready: $@"

# Stage 2 bootloader
$(S2_BIN): $(filter-out $(BUILD_DIR)/boot.o, $(OBJS))
	@echo "Linking stage 2 bootloader..."
	ld -m elf_i386 -T $(S2_LDSCRIPT) $(filter-out $(BUILD_DIR)/boot.o, $(OBJS)) -o $(S2_ELF)
	objcopy -O binary $(S2_ELF) $@
	@echo "Stage2 bootloader ready: $@"
	@echo "Updating offset file with correct address..."
	@$(MAKE) update_offset

# Update the offset file after building (separate target)
update_offset: $(S2_ELF)
	@nm $(S2_ELF) | grep 's2_start' | cut -d ' ' -f1 | xargs printf "S2_START_OFFSET equ 0x%s\n" > $(S2_START_OFFSET)
	@echo "Offset file updated: $(S2_START_OFFSET)"

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
	rm -f $(S2_START_OFFSET)

# Rebuild everything from scratch
rebuild: clean all
	@echo "Rebuilding with correct offsets..."
	@$(MAKE) all

.PHONY: all clean init_inc update_offset rebuild
