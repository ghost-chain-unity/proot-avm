
#!/bin/bash
# proot-avm One-Liner Installer
# This script can be fetched with: curl -fsSL https://alpinevm.qzz.io/install | sh
# Downloads all necessary scripts and sets up complete environment

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration - Auto-detect installation method
if [ -n "$INSTALL_URL" ]; then
    # Custom URL provided
    if [[ "$INSTALL_URL" == *".github.io"* ]]; then
        # GitHub Pages - use direct file serving
        BASE_URL="${INSTALL_URL%/}"
        REPO_URL="${BASE_URL}/install.sh"
    else
        # Raw GitHub or custom domain
        BASE_URL="${INSTALL_URL%/}"
        REPO_URL="${BASE_URL}/install.sh"
    fi
else
    # Default: try GitHub Pages first, fallback to raw.githubusercontent
    GITHUB_PAGES_URL="https://ghost-chain-unity.github.io/proot-avm"
    RAW_GITHUB_URL="https://raw.githubusercontent.com/ghost-chain-unity/proot-avm/main"

    # Test which URL is available
    if curl -fs --max-time 5 "${GITHUB_PAGES_URL}/install.sh" >/dev/null 2>&1; then
        BASE_URL="$GITHUB_PAGES_URL"
        REPO_URL="${BASE_URL}/install.sh"
    else
        BASE_URL="$RAW_GITHUB_URL"
        REPO_URL="https://github.com/ghost-chain-unity/proot-avm/archive/main.tar.gz"
    fi
fi

INSTALL_DIR="${INSTALL_DIR:-$HOME/proot-avm-install}"
TEMP_DIR="${TEMP_DIR:-/tmp/proot-avm-install}"

# Welcome message
echo -e "${MAGENTA}
╔═══════════════════════════════════════════════════════════╗
║  proot-avm One-Liner Installer                          ║
║  Complete Alpine VM Manager Setup                       ║
╚═══════════════════════════════════════════════════════════╝
${NC}"

# Check if we're in Termux
if [ ! -f "/data/data/com.termux/files/usr/bin/bash" ]; then
    echo -e "${RED}❌ This script must be run in Termux${NC}"
    exit 1
fi

# Cleanup function
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up temporary files...${NC}"
    rm -rf "$TEMP_DIR"
    rm -rf "$INSTALL_DIR"
}

# Error handling
error_exit() {
    echo -e "${RED}❌ Error: $1${NC}"
    cleanup
    exit 1
}

# Trap for cleanup on exit
trap cleanup EXIT

# Update package lists
echo -e "${CYAN}🔄 Updating package lists...${NC}"
pkg update -y || error_exit "Failed to update package lists"

# Install dependencies
echo -e "${CYAN}📦 Installing system dependencies...${NC}"
pkg install -y proot-distro qemu-system-x86_64 qemu-utils wget curl openssh git tar gzip || error_exit "Failed to install dependencies"

# Create temporary directory
echo -e "${CYAN}📁 Creating installation directory...${NC}"
mkdir -p "$TEMP_DIR" || error_exit "Failed to create temp directory"
cd "$TEMP_DIR" || error_exit "Failed to change to temp directory"

# Download and extract repository
echo -e "${CYAN}📥 Downloading proot-avm repository...${NC}"
if command -v curl &> /dev/null; then
    curl -fsSL "$REPO_URL" -o repo.tar.gz || error_exit "Failed to download repository"
elif command -v wget &> /dev/null; then
    wget -q "$REPO_URL" -O repo.tar.gz || error_exit "Failed to download repository"
else
    error_exit "Neither curl nor wget available"
fi

echo -e "${CYAN}📦 Extracting repository...${NC}"
tar -xzf repo.tar.gz || error_exit "Failed to extract repository"
cd proot-avm-main || error_exit "Failed to enter extracted directory"

# Copy all necessary scripts
echo -e "${CYAN}📋 Installing scripts...${NC}"
mkdir -p "$HOME/proot-avm" || error_exit "Failed to create proot-avm directory"

# Copy main scripts
cp avm-go.sh "$HOME/proot-avm/" 2>/dev/null || echo "Warning: avm-go.sh not found"
cp dashboard-v2.sh "$HOME/proot-avm/" 2>/dev/null || echo "Warning: dashboard-v2.sh not found"
cp docs.sh "$HOME/proot-avm/" 2>/dev/null || echo "Warning: docs.sh not found"
cp install.sh "$HOME/proot-avm/" 2>/dev/null || echo "Warning: install.sh not found"
cp tui.sh "$HOME/proot-avm/" 2>/dev/null || echo "Warning: tui.sh not found"

# Copy scripts directory
if [ -d "scripts" ]; then
    cp -r scripts "$HOME/proot-avm/" || error_exit "Failed to copy scripts directory"
fi

# Copy other necessary files
cp README.md "$HOME/proot-avm/" 2>/dev/null || echo "Warning: README.md not found"
cp SETUP.md "$HOME/proot-avm/" 2>/dev/null || echo "Warning: SETUP.md not found"
cp LICENSE "$HOME/proot-avm/" 2>/dev/null || echo "Warning: LICENSE not found"

# Make scripts executable
chmod +x "$HOME/proot-avm/"*.sh 2>/dev/null || true
chmod +x "$HOME/proot-avm/scripts/"*.sh 2>/dev/null || true

# Change to proot-avm directory and run installer
echo -e "${CYAN}🚀 Running main installer...${NC}"
cd "$HOME/proot-avm" || error_exit "Failed to change to proot-avm directory"

# Allow passing options via env var or default to agent mode
INSTALL_OPTS="${INSTALL_OPTS:---agent}"
./install.sh $INSTALL_OPTS || error_exit "Main installer failed"

# Setup additional launchers
echo -e "${CYAN}🔗 Setting up additional launchers...${NC}"

# Setup Go CLI launcher
if [ -f "avm-go.sh" ]; then
    chmod +x avm-go.sh
    mkdir -p "$HOME/.local/bin" 2>/dev/null || true
    ln -sf "$HOME/proot-avm/avm-go.sh" "$HOME/.local/bin/avm-go" 2>/dev/null || true
fi

# Setup dashboard launcher
if [ -f "dashboard-v2.sh" ]; then
    chmod +x dashboard-v2.sh
    ln -sf "$HOME/proot-avm/dashboard-v2.sh" "$HOME/.local/bin/avm-dashboard" 2>/dev/null || true
fi

# Setup TUI launcher
if [ -f "tui.sh" ]; then
    chmod +x tui.sh
    ln -sf "$HOME/proot-avm/tui.sh" "$HOME/.local/bin/avm-tui" 2>/dev/null || true
fi

# Setup docs launcher
if [ -f "docs.sh" ]; then
    chmod +x docs.sh
    ln -sf "$HOME/proot-avm/docs.sh" "$HOME/.local/bin/avm-docs" 2>/dev/null || true
fi

# Update PATH if needed
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo 'export PATH="$PATH:$HOME/.local/bin"' >> "$HOME/.bashrc"
    export PATH="$PATH:$HOME/.local/bin"
fi

# Final success message
echo -e "${MAGENTA}
🎉 Complete installation successful!

Available commands:
  $ avm start          # Start Alpine VM (legacy)
  $ avm-go start       # Start VM with Go CLI (modern)
  $ avm-go dashboard   # Launch web dashboard
  $ avm-go tui         # Launch terminal UI
  $ avm-go docs        # View documentation
  $ avm-go --help      # Show all commands

Quick start guide:
  1. avm-go first-boot    # Setup Alpine (one-time)
  2. avm-go start         # Start VM
  3. avm-go ssh          # Connect via SSH

💡 Note: Please restart your terminal or run 'source ~/.bashrc' to apply changes.
${NC}"

# Don't cleanup on success
trap - EXIT
