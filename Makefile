# proot-avm Makefile
.PHONY: all build test clean install lint docs help

# Default target
all: build test

# Build Go CLI
build:
	cd avm-go && go build -o ../dist/avm .

# Build for multiple platforms
build-all:
	mkdir -p dist
	cd avm-go && \
		GOOS=linux GOARCH=amd64 go build -o ../dist/avm-linux-amd64 . && \
		GOOS=linux GOARCH=arm64 go build -o ../dist/avm-linux-arm64 . && \
		GOOS=darwin GOARCH=amd64 go build -o ../dist/avm-darwin-amd64 . && \
		GOOS=darwin GOARCH=arm64 go build -o ../dist/avm-darwin-arm64 . && \
		GOOS=windows GOARCH=amd64 go build -o ../dist/avm-windows-amd64.exe .

# Run tests
test:
	cd avm-go && go test -v -race -cover ./...
	./scripts/utils/test-installer.sh
	./scripts/utils/test-website.sh

# Run linting
lint:
	cd avm-go && go vet ./...
	find scripts -name "*.sh" -exec shellcheck {} \;
	cd avm-go && gofmt -d .

# Format code
fmt:
	cd avm-go && gofmt -w .
	find scripts -name "*.sh" -exec shfmt -w {} \;

# Clean build artifacts
clean:
	rm -rf dist/
	cd avm-go && go clean

# Install locally
install: build
	sudo cp dist/avm /usr/local/bin/avm-go

# Build documentation
docs:
	cd docs && npm install && npm run build

# Development setup
dev-setup:
	./scripts/install/install.sh --dev

# Run CI locally
ci: lint test build-all

# Show help
help:
	@echo "Available targets:"
	@echo "  all        - Build and test (default)"
	@echo "  build      - Build Go CLI"
	@echo "  build-all  - Build for all platforms"
	@echo "  test       - Run all tests"
	@echo "  lint       - Run linting"
	@echo "  fmt        - Format code"
	@echo "  clean      - Clean build artifacts"
	@echo "  install    - Install locally"
	@echo "  docs       - Build documentation"
	@echo "  dev-setup  - Setup development environment"
	@echo "  ci         - Run full CI pipeline locally"
	@echo "  help       - Show this help"