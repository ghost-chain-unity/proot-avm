
#!/bin/bash
# proot-avm One-Liner Installer
# This script can be fetched with: curl -fsSL https://proot.avm.dev/install | sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Welcome message
echo -e "${MAGENTA}
╔═══════════════════════════════════════════════════════════╗
║  proot-avm One-Liner Installer                          ║
║  Alpine VM Manager for Termux                           ║
╚═══════════════════════════════════════════════════════════╝
${NC}"

# Check if we're in Termux
if [ ! -f "/data/data/com.termux/files/usr/bin/bash" ]; then
    echo -e "${RED}❌ This script must be run in Termux${NC}"
    exit 1
fi

# Update package lists
echo -e "${CYAN}🔄 Updating package lists...${NC}"
pkg update -y

# Install dependencies
echo -e "${CYAN}📦 Installing dependencies...${NC}"
pkg install -y proot-distro qemu-system-x86_64 qemu-utils wget curl openssh

# Download the main installer
echo -e "${CYAN}📥 Downloading main installer...${NC}"
curl -fsSL https://raw.githubusercontent.com/ghost-chain-unity/proot-avm/main/install.sh -o install.sh
chmod +x install.sh

# Run the installer
echo -e "${CYAN}🚀 Running installer...${NC}"
./install.sh

# Clean up
rm install.sh

echo -e "${MAGENTA}
🎉 Installation complete!

Quick start:
  $ avm start    # Start Alpine VM
  $ avm ssh      # SSH into VM
  $ avm help     # Show all commands

💡 Note: Please restart your terminal or run 'source ~/.bashrc' to apply changes.
${NC}"
