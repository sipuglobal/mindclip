BINARY = mindclip
INSTALL_DIR = /usr/local/bin

.PHONY: build install clean

build:
	swiftc -O $(BINARY).swift -o $(BINARY)

install: build
	cp $(BINARY) $(INSTALL_DIR)/$(BINARY)
	chmod +x $(INSTALL_DIR)/$(BINARY)

clean:
	rm -f $(BINARY)
