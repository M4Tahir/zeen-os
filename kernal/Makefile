BUILD_DIR := ../build/kernel

KERNEL_SRCS := $(wildcard *.c)
KERNEL_OBJS := $(patsubst %.c, $(BUILD_DIR)/%.o, $(KERNAL_SRCS))
KERNEL := $(BUILD_DIR)/kernal

CFLAGS := -ffreestanding -nostdlib -gdwarf-4 -m32 -ggdb3

all: $(KERNEL)

$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	gcc $(CFLAGS) -c $< -o $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(KERNEL): $(KERNAL_OBJS)
	ld -m elf_i386 -nmagic -T kernel.lds $(KERNEL_OBJS) -o $@

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean

