BINARY = mindclip
INSTALL_DIR = $(HOME)/.local/bin
BUILD_DIR = .build
ARCH = $(shell uname -m)
SDKROOT = $(shell xcrun --sdk macosx --show-sdk-path)
MACOSX_DEPLOYMENT_TARGET ?= 14.0
SWIFTC = /usr/bin/swiftc
SWIFTC_FLAGS = -O \
	-sdk $(SDKROOT) \
	-target $(ARCH)-apple-macosx$(MACOSX_DEPLOYMENT_TARGET) \
	-module-cache-path $(BUILD_DIR)/module-cache \
	-Xcc -fmodules-cache-path=$(CURDIR)/$(BUILD_DIR)/clang-module-cache

.PHONY: build install clean

build:
	mkdir -p $(BUILD_DIR)/module-cache $(BUILD_DIR)/clang-module-cache
	$(SWIFTC) $(SWIFTC_FLAGS) $(BINARY).swift -o $(BINARY)

install: build
	mkdir -p $(INSTALL_DIR)
	cp $(BINARY) $(INSTALL_DIR)/$(BINARY)
	chmod +x $(INSTALL_DIR)/$(BINARY)

clean:
	rm -f $(BINARY)
	rm -rf $(BUILD_DIR)
