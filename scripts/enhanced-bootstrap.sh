
#!/bin/sh
# Enhanced Alpine Linux Bootstrap Script
# Runs inside Alpine VM after first boot with better error handling

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Error handling
error_exit() {
    echo -e "${RED}❌ Error: $1${NC}"
    exit 1
}

echo -e "${GREEN}🚀 Bootstrapping Alpine development environment...${NC}"

# Update repositories
setup-apkrepos -f || error_exit "Failed to setup repositories"

# Update system
apk update || error_exit "Failed to update system"
apk upgrade || error_exit "Failed to upgrade system"

# Install core packages
echo -e "${YELLOW}📦 Installing core packages...${NC}"
apk add docker docker-cli-compose containerd build-base git curl wget || error_exit "Failed to install core packages"

# Enable services
echo -e "${YELLOW}🔧 Enabling services...${NC}"
rc-update add docker boot || error_exit "Failed to enable Docker"
rc-update add containerd boot || error_exit "Failed to enable containerd"
service docker start || error_exit "Failed to start Docker"

# Install UV (Python version manager)
echo -e "${YELLOW}🐍 Installing UV (Python version manager)...${NC}"
curl -LsSf https://astral.sh/uv/install.sh | sh || error_exit "Failed to install UV"
source $HOME/.cargo/env

# Install Python 3.12
echo -e "${YELLOW}🐍 Installing Python 3.12...${NC}"
uv python install 3.12 || error_exit "Failed to install Python 3.12"
uv python pin 3.12 || error_exit "Failed to pin Python 3.12"

# Install Rust
echo -e "${YELLOW}🦀 Installing Rust...${NC}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || error_exit "Failed to install Rust"
source $HOME/.cargo/env

# Install Node.js
echo -e "${YELLOW}📦 Installing Node.js...${NC}"
apk add nodejs npm || error_exit "Failed to install Node.js"

# SSH setup
echo -e "${YELLOW}🔐 Setting up SSH...${NC}"
apk add openssh || error_exit "Failed to install OpenSSH"
rc-update add sshd default || error_exit "Failed to enable SSH"
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config || error_exit "Failed to configure SSH"
service sshd start || error_exit "Failed to start SSH"

echo -e "${GREEN}✅ Bootstrap complete!${NC}"
