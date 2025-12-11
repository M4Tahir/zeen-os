BUILD_DIR := ../build/boot
ASM_SRCS := $(wildcard *.asm)
OBJS := $(patsubst %.asm,$(BUILD_DIR)/%.o,$(ASM_SRCS))
S1_LDSCRIPT := boot.lds
S1_BIN := $(BUILD_DIR)/boot.bin
S1_ELF := $(BUILD_DIR)/boot.elf
S2_LDSCRIPT := stage2.lds
S2_BIN := $(BUILD_DIR)/stage2-boot.bin
S2_ELF := $(BUILD_DIR)/stage2-boot.elf

all:  $(S1_BIN) $(S2_BIN)


# Assemble: .asm → .o (with debug info)
# Now depends on init_inc to ensure .inc exists
$(BUILD_DIR)/%.o: %.asm | $(BUILD_DIR)
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

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
	rm -f $(S2_START_OFFSET)

# Rebuild everything from scratch
rebuild: clean all
	@echo "Rebuilding..."
	@$(MAKE) all

.PHONY: all clean rebuild
