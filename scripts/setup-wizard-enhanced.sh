
#!/usr/bin/env bash

# Enhanced Alpine VM Setup Wizard
# Fully automated setup with better error handling and user experience

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Error handling function
handle_error() {
    echo -e "${RED}❌ Error: $1${NC}"
    echo -e "${YELLOW}💡 Please check the logs and try again.${NC}"
    exit 1
}

# Welcome screen
show_welcome() {
    echo -e "${MAGENTA}
╔═══════════════════════════════════════════════════════════╗
║  ENHANCED ALPINE VM SETUP WIZARD                         ║
║  Fully Automated Docker + Dev Environment               ║
╚═══════════════════════════════════════════════════════════╝
${NC}"
}

# Configuration options
get_user_config() {
    echo -e "${CYAN}📋 Configuration Options${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════${NC}"

    # VM RAM
    read -p "VM RAM (MB) [2048]: " VM_RAM
    VM_RAM=${VM_RAM:-2048}

    # VM CPU
    read -p "VM CPU cores [2]: " VM_CPU
    VM_CPU=${VM_CPU:-2}

    # Disk size
    read -p "Disk size (GB) [10]: " DISK_SIZE
    DISK_SIZE=${DISK_SIZE:-10}

    # SSH port
    read -p "SSH port [2222]: " SSH_PORT
    SSH_PORT=${SSH_PORT:-2222}

    echo -e "${GREEN}✅ Configuration saved${NC}"
}

# Step 1: Install proot-distro and setup Ubuntu environment
setup_proot_environment() {
    echo -e "${CYAN}[1/7] Setting up proot-distro Ubuntu environment...${NC}"

    # Install proot-distro
    pkg install -y proot-distro || handle_error "Failed to install proot-distro"

    # Install Ubuntu
    proot-distro install ubuntu || handle_error "Failed to install Ubuntu"

    # Update and install packages in Ubuntu
    proot-distro login ubuntu --termux-home -- bash -c "
        apt-get update -qq && apt-get install -y wget curl qemu-utils openssh-server
    " || handle_error "Failed to install packages in Ubuntu"

    echo -e "${GREEN}✅ proot-distro Ubuntu environment ready${NC}"
}

# Step 2: Download Alpine ISO
download_alpine_iso() {
    echo -e "${CYAN}[2/7] Downloading Alpine Linux ISO...${NC}"

    mkdir -p ~/qemu-vm || handle_error "Failed to create directory"
    cd ~/qemu-vm || handle_error "Failed to change directory"

    wget -q --show-progress https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-virt-3.18.0-x86_64.iso -O alpine.iso || handle_error "Failed to download Alpine ISO"

    echo -e "${GREEN}✅ Alpine ISO downloaded${NC}"
}

# Step 3: Create VM disk image
create_vm_disk() {
    echo -e "${CYAN}[3/7] Creating virtual disk (${DISK_SIZE}GB)...${NC}"

    proot-distro login ubuntu --termux-home -- bash -c "
        cd ~/qemu-vm && qemu-img create -f qcow2 alpine-docker.img ${DISK_SIZE}G
    " || handle_error "Failed to create VM disk"

    echo -e "${GREEN}✅ Virtual disk created${NC}"
}

# Step 4: First boot - Alpine setup
first_boot_setup() {
    echo -e "${CYAN}[4/7] First boot - Alpine setup required${NC}"
    echo -e "${YELLOW}💡 Please follow the prompts in the VM console...${NC}"

    # Start VM for initial setup
    proot-distro login ubuntu --termux-home -- bash -c "
        cd ~/qemu-vm && qemu-system-x86_64 -m $VM_RAM -smp $VM_CPU -hda alpine-docker.img -cdrom alpine.iso -boot d -nographic
    " || handle_error "Failed to start VM for initial setup"

    echo -e "${GREEN}✅ Initial Alpine setup complete${NC}"
}

# Step 5: Install development environment
install_dev_environment() {
    echo -e "${CYAN}[5/7] Installing development environment...${NC}"

    # Copy bootstrap script to VM
    proot-distro login ubuntu --termux-home -- bash -c "
        cd ~/qemu-vm && cp \"$SCRIPT_DIR/../scripts/alpine-bootstrap.sh\" .
        chmod +x alpine-bootstrap.sh
        ./alpine-bootstrap.sh
    " || handle_error "Failed to install development environment"

    echo -e "${GREEN}✅ Development environment installed${NC}"
}

# Step 6: Install AVM management tool
install_avm() {
    echo -e "${CYAN}[6/7] Installing AVM management tool...${NC}"

    # Prefer repo-local script when running from source tree
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

    cp "$SCRIPT_DIR/../scripts/alpine-vm.sh" ~/qemu-vm/ 2>/dev/null || cp /usr/bin/alpine-vm.sh ~/qemu-vm/ || handle_error "Failed to copy AVM script"
    chmod +x ~/qemu-vm/alpine-vm.sh || handle_error "Failed to set permissions"

    # Create user-local symlink (avoid requiring root)
    mkdir -p "$HOME/.local/bin" || handle_error "Failed to create local bin"
    ln -sf "$HOME/qemu-vm/alpine-vm.sh" "$HOME/.local/bin/avm" || handle_error "Failed to create symlink"
    grep -qxF 'export PATH="$PATH:$HOME/.local/bin"' ~/.bashrc || echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc || handle_error "Failed to update bashrc PATH"

    echo -e "${GREEN}✅ AVM management tool installed${NC}"
}

# Step 7: Configure bashrc and environment
configure_environment() {
    echo -e "${CYAN}[7/7] Configuring bashrc and environment...${NC}"

    # Add alias to Termux bashrc
    echo 'alias avm="~/alpine-start.sh"' >> ~/.bashrc || handle_error "Failed to update Termux bashrc"

    # Add alias to proot-distro bashrc
    proot-distro login ubuntu --termux-home -- bash -c "
        echo 'alias avm=\"~/alpine-vm.sh\"' >> ~/.bashrc
        echo 'export PATH=\$PATH:~/qemu-vm' >> ~/.bashrc
    " || handle_error "Failed to update proot-distro bashrc"

    # Make scripts executable in proot-distro
    proot-distro login ubuntu --termux-home -- bash -c "
        chmod +x ~/alpine-vm.sh
        chmod +x ~/qemu-vm/alpine-vm.sh
    " || handle_error "Failed to set script permissions"

    echo -e "${GREEN}✅ Environment configured${NC}"
}

# Show completion message
show_completion() {
    echo -e "${MAGENTA}
🎉 Setup complete!

Quick start:
  $ avm start    # Start Alpine VM
  $ avm ssh      # SSH into VM
  $ avm help     # Show all commands

💡 Note: Please restart your terminal or run 'source ~/.bashrc' to apply changes.
${NC}"
}

# Main script execution
show_welcome
get_user_config
setup_proot_environment
download_alpine_iso
create_vm_disk
first_boot_setup
install_dev_environment
install_avm
configure_environment
show_completion
