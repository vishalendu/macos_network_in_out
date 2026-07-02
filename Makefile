APP_NAME := Network In Out
BUNDLE := build/$(APP_NAME).app
BIN := $(BUNDLE)/Contents/MacOS/NetworkInOut

.PHONY: build test run clean

build:
	mkdir -p "$(BUNDLE)/Contents/MacOS"
	mkdir -p "$(BUNDLE)/Contents/Resources"
	mkdir -p build/module-cache
	swiftc -module-cache-path build/module-cache Sources/NetworkInOut/main.swift -o "$(BIN)" -framework AppKit
	cp Info.plist "$(BUNDLE)/Contents/Info.plist"

test: build
	"$(BIN)" --self-test

run: build
	open "$(BUNDLE)"

clean:
	rm -rf build
