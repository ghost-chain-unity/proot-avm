
#!/usr/bin/env bash
# DEPRECATED: proot-avm Installation Agent (Legacy)
# This script is deprecated. Use install.sh --agent instead.
# Will be removed in future versions.

echo "⚠️  WARNING: This script is deprecated!"
echo "   Please use: ./install.sh --agent"
echo "   Or run: curl -sSL https://alpinevm.qzz.io/install | bash"
echo ""
read -p "Continue anyway? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Original code follows...

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Repository root (when running from source tree)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

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

# Welcome screen
show_welcome() {
    clear
    echo -e "${MAGENTA}
╔═══════════════════════════════════════════════════════════╗
║  proot-avm Installation Agent                          ║
║  Modern Alpine VM Manager for Termux                   ║
╚═══════════════════════════════════════════════════════════╝
${NC}"
    echo -e "${CYAN}🚀 Starting installation...${NC}"
    sleep 1
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

# Download and setup Alpine VM
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

# Install development environment
install_dev_env() {
    echo -e "${CYAN}[4/5] Installing development environment...${NC}"
    progress_bar 4 &

    # Install packages in Ubuntu
    proot-distro login ubuntu --termux-home -- bash -c "
        apt-get update -qq && apt-get install -y wget curl qemu-utils openssh-server
    " || handle_error "Failed to install packages in Ubuntu"

    # Install packages in Alpine
    proot-distro login ubuntu --termux-home -- bash -c "
        cd ~/qemu-vm && cp /usr/bin/enhanced-bootstrap.sh .
        chmod +x enhanced-bootstrap.sh
        ./enhanced-bootstrap.sh
    " || handle_error "Failed to install development environment"
        # Install packages in Alpine
        proot-distro login ubuntu --termux-home -- bash -c "
            cd ~/qemu-vm && cp \"$REPO_DIR/scripts/enhanced-bootstrap.sh\" .
            chmod +x enhanced-bootstrap.sh
            ./enhanced-bootstrap.sh
        " || handle_error "Failed to install development environment"

    echo -e "${GREEN}✅ Development environment installed${NC}"
}

# Final configuration
final_config() {
    echo -e "${CYAN}[5/5] Final configuration...${NC}"
    progress_bar 2 &

    # Copy scripts (prefer repo scripts when available)
    cp "$REPO_DIR/scripts/alpine-vm.sh" ~/qemu-vm/ 2>/dev/null || cp /usr/bin/alpine-vm.sh ~/qemu-vm/ || handle_error "Failed to copy AVM script"
    chmod +x ~/qemu-vm/alpine-vm.sh || handle_error "Failed to set permissions"

    # Create user-local symlink (avoid requiring root)
    mkdir -p "$HOME/.local/bin" || handle_error "Failed to create local bin"
    ln -sf "$HOME/qemu-vm/alpine-vm.sh" "$HOME/.local/bin/avm" || handle_error "Failed to create symlink"

    # Configure bashrc
    echo 'alias avm="~/alpine-start.sh"' >> ~/.bashrc || handle_error "Failed to update bashrc"

    # Configure proot-distro bashrc
    proot-distro login ubuntu --termux-home -- bash -c "
        echo 'alias avm=\"~/alpine-vm.sh\"' >> ~/.bashrc
        echo 'export PATH=\$PATH:~/qemu-vm' >> ~/.bashrc
    " || handle_error "Failed to update proot-distro bashrc"
        proot-distro login ubuntu --termux-home -- bash -c "
            echo 'alias avm=\"~/alpine-vm.sh\"' >> ~/.bashrc
            grep -qxF 'export PATH=\"\$PATH:~/qemu-vm\"' ~/.bashrc || echo 'export PATH=\"\$PATH:~/qemu-vm\"' >> ~/.bashrc
        " || handle_error "Failed to update proot-distro bashrc"

    echo -e "${GREEN}✅ Configuration complete${NC}"
}

# Show completion message
show_completion() {
    echo -e "${MAGENTA}
🎉 Installation complete!

Quick start:
  $ avm start    # Start Alpine VM
  $ avm ssh      # SSH into VM
  $ avm help     # Show all commands

💡 Note: Please restart your terminal or run 'source ~/.bashrc' to apply changes.
${NC}"
}

# Main script execution
show_welcome
check_dependencies
install_proot
setup_alpine_vm
install_dev_env
final_config
show_completion
