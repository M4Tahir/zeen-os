BUILD_DIR := ../build/boot

ASM_SRCS := $(wildcard *.asm)
OBJS := $(patsubst %.asm,$(BUILD_DIR)/%.o,$(ASM_SRCS))

S1_LDSCRIPT := boot.lds
S1_BIN := $(BUILD_DIR)/boot.bin
S1_ELF := $(BUILD_DIR)/boot.elf

S2_LDSCRIPT := stage2.lds
S2_BIN := $(BUILD_DIR)/stage2-boot.bin
S2_ELF := $(BUILD_DIR)/stage2-boot.elf

all: $(S1_BIN) $(S2_BIN)

# Assemble: .asm → .o (with debug info)
$(BUILD_DIR)/%.o: %.asm | $(BUILD_DIR)
	@echo "Assembling $<..."
	nasm -f elf $< -F dwarf -g -o $@
	@echo "Done: $@"

# Per-file ELF for debugging
$(BUILD_DIR)/%.elf: $(BUILD_DIR)/%.o
	@echo "Creating debug ELF for $<..."
	ld -m elf_i386 -o $@ $<
	@echo "Done: $@"

# Stage 1 bootloader
$(S1_BIN): $(OBJS)
	@echo "Linking stage 1 bootloader..."
	# ld -m elf_i386 -T $(S1_LDSCRIPT) $(OBJS) -o $(S1_ELF) # this cause bug as the linker script will grab all the .text section from all objects
	ld -m elf_i386 -T $(S1_LDSCRIPT) $(BUILD_DIR)/boot.o -o $(S1_ELF)	
	objcopy -O binary $(S1_ELF) $@
	@echo "Bootloader ready: $@"

# Stage 2 bootloader: Don't include boot.o in the 2nd stage as in lds .text will inlcude text sec from all objs file
$(S2_BIN): $(filter-out $(BUILD_DIR)/boot.o, $(OBJS))
	@echo "Linking stage 2 bootloader..."
	ld -m elf_i386 -T $(S2_LDSCRIPT) $(OBJS) -o $(S2_ELF)
	objcopy -O binary $(S2_ELF) $@
	@echo "Stage2 bootloader ready: $@"

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean
