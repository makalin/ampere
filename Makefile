.PHONY: all build-core build-macos build-windows clean test help

# Default target
all: build-core

# Build Rust core
build-core:
	@echo "Building Rust core..."
	cd core && cargo build --release

# Build macOS app (requires Xcode)
build-macos: build-core
	@echo "Building macOS app..."
	@echo "Note: Open macos/Ampere.xcodeproj in Xcode to build the app"

# Build Windows app (requires Visual Studio)
build-windows: build-core
	@echo "Building Windows app..."
	@echo "Note: Open windows/Ampere.sln in Visual Studio to build the app"

# Run tests
test:
	@echo "Running Rust tests..."
	cd core && cargo test

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	cd core && cargo clean
	rm -rf macos/build
	rm -rf windows/bin windows/obj

# Help
help:
	@echo "Available targets:"
	@echo "  all          - Build Rust core (default)"
	@echo "  build-core   - Build Rust core library"
	@echo "  build-macos  - Build macOS app (requires Xcode)"
	@echo "  build-windows- Build Windows app (requires Visual Studio)"
	@echo "  test         - Run Rust tests"
	@echo "  clean        - Clean all build artifacts"
	@echo "  help         - Show this help message"

