BUILD_DIR := ../build/kernal

KERNAL_SRCS := $(wildcard *.asm)
KERNAL_OBJS := $(patsubst %.asm, $(BUILD_DIR)/%.o, $(KERNAL_SRCS))

.PHONY: all clean

all: $(KERNAL_OBJS)

$(BUILD_DIR)/%.o: %.asm | $(BUILD_DIR)
	nasm -f bin $< -o $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
