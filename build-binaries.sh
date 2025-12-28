#!/usr/bin/env bash
# proot-avm Binary Builder and Releaser
# Builds optimized binaries for multiple platforms

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
BUILD_DIR="${BUILD_DIR:-./build}"
RELEASE_DIR="${RELEASE_DIR:-./release}"
VERSION="${VERSION:-v2.0.0}"

# Supported platforms
PLATFORMS=(
    "linux/amd64"
    "linux/arm64"
    "android/arm64"
    "darwin/amd64"
    "darwin/arm64"
    "windows/amd64"
)

echo -e "${MAGENTA}
╔═══════════════════════════════════════════════════════════╗
║  proot-avm Binary Builder                               ║
║  Multi-platform Release Builder                         ║
╚═══════════════════════════════════════════════════════════╝
${NC}"

# Check dependencies
check_dependencies() {
    echo -e "${CYAN}🔍 Checking dependencies...${NC}"

    if ! command -v go &> /dev/null; then
        echo -e "${RED}❌ Go not found. Please install Go first.${NC}"
        exit 1
    fi

    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git not found. Please install Git first.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Dependencies OK${NC}"
}

# Setup build environment
setup_build() {
    echo -e "${CYAN}📁 Setting up build environment...${NC}"

    mkdir -p "$BUILD_DIR"
    mkdir -p "$RELEASE_DIR"

    # Clean previous builds
    rm -rf "$BUILD_DIR"/*
    rm -rf "$RELEASE_DIR"/*

    echo -e "${GREEN}✅ Build environment ready${NC}"
}

# Build Go CLI for specific platform
build_platform() {
    local platform="$1"
    local goos="${platform%/*}"
    local goarch="${platform#*/}"

    echo -e "${CYAN}🔨 Building for $goos/$goarch...${NC}"

    local output_name="avm-go"
    if [ "$goos" = "windows" ]; then
        output_name="avm-go.exe"
    fi

    local output_path="$BUILD_DIR/$output_name-$goos-$goarch"

    cd avm-go

    # Set environment variables
    export GOOS="$goos"
    export GOARCH="$goarch"

    # Special handling for android
    if [ "$goos" = "android" ]; then
        export GOOS="linux"
        export CGO_ENABLED=1
        export CC="${CC:-aarch64-linux-android21-clang}"
    fi

    # Build with optimizations
    go build \
        -ldflags="-s -w -X main.version=$VERSION -X main.buildTime=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        -trimpath \
        -o "$output_path" \
        .

    # Reset environment
    unset GOOS GOARCH CGO_ENABLED CC

    cd ..

    echo -e "${GREEN}✅ Built $output_path${NC}"
}

# Build all platforms
build_all() {
    echo -e "${CYAN}🚀 Building for all platforms...${NC}"

    for platform in "${PLATFORMS[@]}"; do
        build_platform "$platform"
    done

    echo -e "${GREEN}✅ All platforms built${NC}"
}

# Create release archives
create_releases() {
    echo -e "${CYAN}📦 Creating release archives...${NC}"

    cd "$BUILD_DIR"

    for binary in *; do
        if [ -f "$binary" ]; then
            local platform="${binary#avm-go-}"
            platform="${platform%.exe}"

            # Create tar.gz archive
            if [[ "$binary" == *.exe ]]; then
                # Windows - create zip
                zip "$RELEASE_DIR/avm-go-$platform.zip" "$binary"
            else
                # Unix-like - create tar.gz
                tar -czf "$RELEASE_DIR/avm-go-$platform.tar.gz" "$binary"
            fi

            echo -e "${GREEN}✅ Created $RELEASE_DIR/avm-go-$platform archive${NC}"
        fi
    done

    cd ..
}

# Create installer scripts for each platform
create_installers() {
    echo -e "${CYAN}📜 Creating installer scripts...${NC}"

    for platform in "${PLATFORMS[@]}"; do
        local goos="${platform%/*}"
        local goarch="${platform#*/}"
        local binary_name="avm-go-$goos-$goarch"

        if [ "$goos" = "windows" ]; then
            binary_name="avm-go-$goos-$goarch.exe"
        fi

        local installer_script="$RELEASE_DIR/install-$goos-$goarch.sh"

        cat > "$installer_script" << EOF
#!/bin/bash
# proot-avm Binary Installer for $goos/$goarch
# Version: $VERSION

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "\${MAGENTA}
╔═══════════════════════════════════════════════════════════╗
║  proot-avm Binary Installer                            ║
║  Platform: $goos/$goarch  Version: $VERSION            ║
╚═══════════════════════════════════════════════════════════╝
\${NC}"

# Check platform compatibility
check_platform() {
    case "$goos" in
        "linux")
            if [ ! -f "/data/data/com.termux/files/usr/bin/bash" ]; then
                echo -e "\${RED}❌ This binary is for Android/Termux Linux\${NC}"
                exit 1
            fi
            ;;
        "darwin")
            if [ "\$(uname)" != "Darwin" ]; then
                echo -e "\${RED}❌ This binary is for macOS\${NC}"
                exit 1
            fi
            ;;
        "windows")
            if [ "\$(uname)" != "MINGW"* ] && [ "\$(uname)" != "MSYS"* ]; then
                echo -e "\${RED}❌ This binary is for Windows\${NC}"
                exit 1
            fi
            ;;
    esac
}

# Download and install binary
install_binary() {
    echo -e "\${CYAN}📥 Downloading binary...\$NC}"

    BINARY_URL="https://github.com/ghost-chain-unity/proot-avm/releases/download/$VERSION/$binary_name"
    INSTALL_DIR="\$HOME/.local/bin"

    mkdir -p "\$INSTALL_DIR"

    if command -v curl &> /dev/null; then
        curl -fsSL "\$BINARY_URL" -o "\$INSTALL_DIR/avm-go"
    elif command -v wget &> /dev/null; then
        wget -q "\$BINARY_URL" -O "\$INSTALL_DIR/avm-go"
    else
        echo -e "\${RED}❌ Neither curl nor wget available\${NC}"
        exit 1
    fi

    chmod +x "\$INSTALL_DIR/avm-go"

    # Update PATH if needed
    if ! echo "\$PATH" | grep -q "\$INSTALL_DIR"; then
        echo "export PATH=\"\$PATH:\$INSTALL_DIR\"" >> "\$HOME/.bashrc"
        export PATH="\$PATH:\$INSTALL_DIR"
    fi
}

# Main installation
main() {
    check_platform
    install_binary

    echo -e "\${MAGENTA}
🎉 Binary installation complete!

Available commands:
  \$ avm-go --help      # Show all commands
  \$ avm-go start       # Start VM
  \$ avm-go dashboard   # Launch web dashboard
  \$ avm-go tui         # Launch terminal UI

💡 Note: Please restart your terminal or run 'source ~/.bashrc' to apply changes.
\${NC}"
}

main "\$@"
EOF

        chmod +x "$installer_script"
        echo -e "${GREEN}✅ Created installer for $goos/$goarch${NC}"
    done
}

# Create checksums
create_checksums() {
    echo -e "${CYAN}🔐 Creating checksums...${NC}"

    cd "$RELEASE_DIR"

    # Create SHA256 checksums
    sha256sum * > SHA256SUMS.txt 2>/dev/null || true

    # Create MD5 checksums for compatibility
    md5sum * > MD5SUMS.txt 2>/dev/null || true

    cd ..

    echo -e "${GREEN}✅ Checksums created${NC}"
}

# Create release notes
create_release_notes() {
    echo -e "${CYAN}📝 Creating release notes...${NC}"

    cat > "$RELEASE_DIR/RELEASE_NOTES.md" << EOF
# proot-avm $VERSION Release Notes

## 🚀 What's New

- **Complete rewrite in Go** for better performance and cross-platform support
- **Modern web dashboard** with real-time monitoring and AI assistance
- **Terminal UI** with interactive menus and keyboard navigation
- **AI-powered assistance** for intelligent suggestions and troubleshooting
- **Multi-platform binaries** for Linux, macOS, Windows, and Android

## 📦 Downloads

### Linux (amd64)
- [avm-go-linux-amd64.tar.gz](https://github.com/ghost-chain-unity/proot-avm/releases/download/$VERSION/avm-go-linux-amd64.tar.gz)
- [Install Script](https://github.com/ghost-chain-unity/proot-avm/releases/download/$VERSION/install-linux-amd64.sh)

### Linux (arm64)
- [avm-go-linux-arm64.tar.gz](https://github.com/ghost-chain-unity/proot-avm/releases/download/$VERSION/avm-go-linux-arm64.tar.gz)
- [Install Script](https://github.com/ghost-chain-unity/proot-avm/releases/download/$VERSION/install-linux-arm64.sh)

### Android (arm64)
- [avm-go-android-arm64.tar.gz](https://github.com/ghost-chain-unity/proot-avm/releases/download/$VERSION/avm-go-android-arm64.tar.gz)
- [Install Script](https://github.com/ghost-chain-unity/proot-avm/releases/download/$VERSION/install-android-arm64.sh)

### macOS (Intel)
- [avm-go-darwin-amd64.tar.gz](https://github.com/ghost-chain-unity/proot-avm/releases/download/$VERSION/avm-go-darwin-amd64.tar.gz)
- [Install Script](https://github.com/ghost-chain-unity/proot-avm/releases/download/$VERSION/install-darwin-amd64.sh)

### macOS (Apple Silicon)
- [avm-go-darwin-arm64.tar.gz](https://github.com/ghost-chain-unity/proot-avm/releases/download/$VERSION/avm-go-darwin-arm64.tar.gz)
- [Install Script](https://github.com/ghost-chain-unity/proot-avm/releases/download/$VERSION/install-darwin-arm64.sh)

### Windows (amd64)
- [avm-go-windows-amd64.zip](https://github.com/ghost-chain-unity/proot-avm/releases/download/$VERSION/avm-go-windows-amd64.zip)
- [Install Script](https://github.com/ghost-chain-unity/proot-avm/releases/download/$VERSION/install-windows-amd64.sh)

## 🛠️ Installation

### One-liner (Recommended)
\`\`\`bash
curl -fsSL https://alpinevm.qzz.io/install | sh
\`\`\`

### Manual Installation
1. Download the appropriate binary for your platform
2. Extract the archive
3. Move the binary to a directory in your PATH
4. Run \`avm-go --help\` to verify installation

## ✨ Key Features

### Go CLI
- Modern command-line interface
- Cross-platform compatibility
- Fast startup and execution
- Comprehensive help system

### Web Dashboard
- Real-time VM monitoring
- Visual performance metrics
- AI-powered assistance
- Responsive design for mobile

### Terminal UI
- Interactive menu system
- Keyboard navigation
- Real-time status updates
- Command execution

### AI Integration
- Intelligent suggestions
- Automated troubleshooting
- Context-aware help
- Performance optimization tips

## 🔧 System Requirements

- **Linux/Android**: Kernel 3.10+, glibc 2.17+
- **macOS**: 10.12+ (Sierra)
- **Windows**: Windows 10 1607+
- **Memory**: 2GB RAM minimum, 4GB recommended
- **Storage**: 10GB free space

## 📚 Documentation

- [Getting Started Guide](https://alpinevm.qzz.io/docs/getting-started/)
- [User Guide](https://alpinevm.qzz.io/docs/user-guide/)
- [Developer Guide](https://alpinevm.qzz.io/docs/developer/)
- [API Reference](https://alpinevm.qzz.io/docs/api/)

## 🐛 Known Issues

- Android: Some QEMU features may require additional setup
- Windows: Hyper-V may conflict with QEMU (disable Hyper-V)
- macOS: Virtualization framework requires macOS 12+

## 🙏 Acknowledgments

Special thanks to:
- The Go community for the amazing language
- QEMU project for virtualization
- Termux project for Android Linux environment
- All contributors and beta testers

---

**Released on:** $(date -u +%Y-%m-%d)
**Version:** $VERSION
EOF

    echo -e "${GREEN}✅ Release notes created${NC}"
}

# Main build process
main() {
    check_dependencies
    setup_build
    build_all
    create_releases
    create_installers
    create_checksums
    create_release_notes

    echo -e "${MAGENTA}
🎉 Build complete!

Release artifacts created in: $RELEASE_DIR

Contents:
$(ls -la "$RELEASE_DIR")

Next steps:
1. Test binaries on target platforms
2. Create GitHub release with artifacts
3. Update documentation with download links
4. Announce release to community

${NC}"
}

# Run main function with all arguments
main "$@"