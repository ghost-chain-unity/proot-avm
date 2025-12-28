
#!/usr/bin/env bash
# proot-avm Unified Installer
# Modern CLI installer with progress bars, error handling, and full automation

# Source shared functions
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/scripts/shared-functions.sh"

# Welcome screen
show_welcome() {
    clear
    echo -e "${MAGENTA}
╔═══════════════════════════════════════════════════════════╗
║  proot-avm Unified Installer                            ║
║  Modern Alpine VM Manager for Termux                     ║
╚═══════════════════════════════════════════════════════════╝
${NC}"
    echo -e "${CYAN}🚀 Starting installation...${NC}"
    sleep 1
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

# Install development environment with agent
install_dev_env_agent() {
    echo -e "${CYAN}[4/5] Installing development environment with agent...${NC}"
    progress_bar 4 &

    # Install packages in Ubuntu
    proot-distro login ubuntu --termux-home -- bash -c "
        apt-get update -qq && apt-get install -y wget curl qemu-utils openssh-server
    " || handle_error "Failed to install packages in Ubuntu"

    # Copy and run agent in Alpine VM
    proot-distro login ubuntu --termux-home -- bash -c "
        cd ~/qemu-vm && cp \"$REPO_DIR/scripts/avm-agent.sh\" .
        chmod +x avm-agent.sh
        ./avm-agent.sh
    " || handle_error "Failed to run agent in Alpine VM"

    echo -e "${GREEN}✅ Development environment with agent installed${NC}"
}

# Final configuration
final_config() {
    echo -e "${CYAN}[5/5] Final configuration...${NC}"
    progress_bar 2 &

    # Copy scripts
    cp ~/proot-avm/scripts/alpine-vm.sh ~/qemu-vm/ || handle_error "Failed to copy AVM script"
    cp ~/proot-avm/scripts/alpine-start.sh ~/ || handle_error "Failed to copy start script"
    chmod +x ~/qemu-vm/alpine-vm.sh || handle_error "Failed to set permissions"


    # Install into user-local bin to avoid requiring root
    mkdir -p "$HOME/.local/bin" || handle_error "Failed to create local bin"
    ln -sf "$HOME/qemu-vm/alpine-vm.sh" "$HOME/.local/bin/avm" || handle_error "Failed to create symlink"

    # Configure bashrc (alias + ensure local bin is in PATH)
    echo 'alias avm="~/alpine-start.sh"' >> ~/.bashrc || handle_error "Failed to update bashrc"
    grep -qxF 'export PATH="$PATH:$HOME/.local/bin"' ~/.bashrc || echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc || handle_error "Failed to update bashrc PATH"

    # Configure proot-distro bashrc
    proot-distro login ubuntu --termux-home -- bash -c "
        echo '# proot-avm AI Configuration' >> ~/.bashrc
        echo '# Set your preferred AI provider: openai, claude, ollama, openhands' >> ~/.bashrc
        echo 'export AVM_AI_PROVIDER=\"ollama\"' >> ~/.bashrc
        echo '# export OPENAI_API_KEY=\"your-key-here\"' >> ~/.bashrc
        echo '# export ANTHROPIC_API_KEY=\"your-key-here\"' >> ~/.bashrc
        echo '' >> ~/.bashrc
    " || handle_error "Failed to configure proot-distro bashrc"
        echo 'alias avm=\"~/alpine-vm.sh\"' >> ~/.bashrc
        echo 'export PATH=\$PATH:~/qemu-vm' >> ~/.bashrc
        echo 'export PATH=\$PATH:~/proot-avm/scripts' >> ~/.bashrc
    " || handle_error "Failed to update proot-distro bashrc"

    echo -e "${GREEN}✅ Configuration complete${NC}"
}

# Show completion message
show_completion() {
    echo -e "${MAGENTA}
🎉 Installation complete!

Next steps:
  1. Run: avm first-boot  # Setup Alpine Linux (one-time)
  2. Run: avm start      # Start the VM
  3. Run: avm ssh        # Connect to VM (wait for boot ~1-2 min)

Quick commands:
  $ avm start    # Start Alpine VM
  $ avm ssh      # SSH into VM
  $ avm help     # Show all commands

💡 Note: Please restart your terminal or run 'source ~/.bashrc' to apply changes.
${NC}"
}

# Main script execution
# Parse options
AGENT_MODE=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --agent)
      AGENT_MODE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

show_welcome
check_termux
check_dependencies
install_proot
setup_alpine_vm
if $AGENT_MODE; then
  install_dev_env_agent
else
  install_dev_env
fi
final_config
show_completion
