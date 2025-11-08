BUILD_DIR := ../build/kernal

KERNAL_SRCS := $(wildcard *.c)
KERNAL_OBJS := $(patsubst %.c, $(BUILD_DIR)/%.o, $(KERNAL_SRCS))
KERNAL := $(BUILD_DIR)/kernal

CFLAGS := -ffreestanding -nostdlib -gdwarf-4 -m32 -ggdb3

all: $(KERNAL)

$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	gcc $(CFLAGS) -c $< -o $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(KERNAL): $(KERNAL_OBJS)
	ld -m elf_i386 -nmagic -T kernal.lds $(KERNAL_OBJS) -o $@

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean

