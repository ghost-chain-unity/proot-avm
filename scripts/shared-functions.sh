#!/usr/bin/env bash
# Shared functions for proot-avm scripts
# Source this file to use common functions

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Progress bar function
progress_bar() {
    local duration=${1:-10}
    local width=${2:-50}
    local increment=$((duration * 1000 / width))

    printf "["
    for ((i=0; i<width; i++)); do
        printf "▓"
        usleep $increment
    done
    printf "] 100%%\n"
}

# Error handling
handle_error() {
    echo -e "${RED}❌ Error: $1${NC}"
    echo -e "${YELLOW}💡 Please check the logs and try again.${NC}"
    exit 1
}

# Success message
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Info message
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Warning message
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if we're in Termux
check_termux() {
    if [ ! -f "/data/data/com.termux/files/usr/bin/bash" ]; then
        echo -e "${RED}❌ This script must be run in Termux${NC}"
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    echo -e "${CYAN}[1/5] Checking dependencies...${NC}"
    progress_bar 2 &

    # Check for required commands
    for cmd in curl wget qemu-system-x86_64 proot-distro; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${YELLOW}⚠️  $cmd not found, installing...${NC}"
            pkg install -y $cmd || handle_error "Failed to install $cmd"
        fi
    done

    echo -e "${GREEN}✅ Dependencies checked${NC}"
}

# Install proot-distro
install_proot() {
    echo -e "${CYAN}[2/5] Installing proot-distro...${NC}"
    progress_bar 3 &

    pkg install -y proot-distro || handle_error "Failed to install proot-distro"
    proot-distro install ubuntu || handle_error "Failed to install Ubuntu"

    echo -e "${GREEN}✅ proot-distro installed${NC}"
}

# Setup Alpine VM
setup_alpine_vm() {
    echo -e "${CYAN}[3/5] Setting up Alpine VM...${NC}"
    progress_bar 5 &

    # Create directories
    mkdir -p ~/qemu-vm || handle_error "Failed to create directory"
    cd ~/qemu-vm || handle_error "Failed to change directory"

    # Download Alpine ISO
    echo -e "${YELLOW}📥 Downloading Alpine ISO...${NC}"
    wget -q --show-progress https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-virt-3.18.0-x86_64.iso -O alpine.iso || handle_error "Failed to download Alpine ISO"

    # Create VM disk
    echo -e "${YELLOW}💾 Creating VM disk...${NC}"
    proot-distro login ubuntu --termux-home -- bash -c "
        cd ~/qemu-vm && qemu-img create -f qcow2 alpine-docker.img 10G
    " || handle_error "Failed to create VM disk"

    echo -e "${GREEN}✅ Alpine VM setup complete${NC}"
}

# Final configuration
final_config() {
    echo -e "${CYAN}[5/5] Final configuration...${NC}"
    progress_bar 2 &

    # Copy scripts
    cp ~/proot-avm/scripts/alpine-vm.sh ~/qemu-vm/ || handle_error "Failed to copy AVM script"
    cp ~/proot-avm/scripts/alpine-start.sh ~/ || handle_error "Failed to copy start script"
    chmod +x ~/qemu-vm/alpine-vm.sh || handle_error "Failed to set permissions"

    # Create symlink
    mkdir -p "$HOME/.local/bin" || handle_error "Failed to create local bin"
    ln -sf "$HOME/qemu-vm/alpine-vm.sh" "$HOME/.local/bin/avm" || handle_error "Failed to create symlink"

    # Configure bashrc
    echo 'alias avm="~/alpine-start.sh"' >> ~/.bashrc || handle_error "Failed to update bashrc"
    grep -qxF 'export PATH="$PATH:$HOME/.local/bin"' ~/.bashrc || echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc || handle_error "Failed to update bashrc PATH"

    # Configure proot-distro bashrc
    proot-distro login ubuntu --termux-home -- bash -c "
        echo 'alias avm=\"~/alpine-vm.sh\"' >> ~/.bashrc
        grep -qxF 'export PATH=\"\$PATH:~/qemu-vm\"' ~/.bashrc || echo 'export PATH=\"\$PATH:~/qemu-vm\"' ~/.bashrc
    " || handle_error "Failed to update proot-distro bashrc"

    echo -e "${GREEN}✅ Configuration complete${NC}"
}