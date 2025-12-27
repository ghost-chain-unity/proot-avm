
#!/bin/sh
# proot-avm Agent
# Fully automated setup agent for Alpine VM

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Error handling
error_exit() {
    echo -e "${RED}❌ Error: $1${NC}"
    exit 1
}

# Progress indicator
progress() {
    echo -e "${CYAN}🚀 $1${NC}"
}

# Success indicator
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Welcome message
echo -e "${MAGENTA}
╔═══════════════════════════════════════════════════════════╗
║  proot-avm Agent                                        ║
║  Automating Alpine VM Development Environment Setup    ║
╚═══════════════════════════════════════════════════════════╝
${NC}"

# Update system
progress "Updating system..."
apk update || error_exit "Failed to update system"
apk upgrade || error_exit "Failed to upgrade system"
success "System updated"

# Install core packages
progress "Installing core packages..."
apk add docker docker-cli-compose containerd build-base git curl wget openssh || error_exit "Failed to install core packages"
success "Core packages installed"

# Install UV (Python version manager)
progress "Installing UV (Python version manager)..."
curl -LsSf https://astral.sh/uv/install.sh | sh || error_exit "Failed to install UV"
source $HOME/.cargo/env
success "UV installed"

# Install Python 3.12
progress "Installing Python 3.12..."
uv python install 3.12 || error_exit "Failed to install Python 3.12"
uv python pin 3.12 || error_exit "Failed to pin Python 3.12"
success "Python 3.12 installed"

# Install Rust
progress "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || error_exit "Failed to install Rust"
source $HOME/.cargo/env
success "Rust installed"

# Install Node.js
progress "Installing Node.js..."
apk add nodejs npm || error_exit "Failed to install Node.js"
success "Node.js installed"

# Install Go
progress "Installing Go..."
apk add go || error_exit "Failed to install Go"
success "Go installed"

# Configure SSH
progress "Configuring SSH..."
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config || error_exit "Failed to configure SSH"
rc-update add sshd default || error_exit "Failed to enable SSH"
service sshd start || error_exit "Failed to start SSH"
success "SSH configured"

# Configure Docker
progress "Configuring Docker..."
rc-update add docker boot || error_exit "Failed to enable Docker"
rc-update add containerd boot || error_exit "Failed to enable containerd"
service docker start || error_exit "Failed to start Docker"
success "Docker configured"

# Set up environment variables
progress "Setting up environment variables..."
cat << 'EOF' >> /etc/profile
# proot-avm environment
export PATH=$PATH:$HOME/.cargo/bin:$HOME/.local/bin
export UV_HOME=$HOME/.uv
export PATH=$UV_HOME/bin:$PATH
EOF
success "Environment variables set"

# Final message
echo -e "${MAGENTA}
🎉 proot-avm Agent Setup Complete!

Development environment ready:
- Docker & containerd (auto-start)
- Python 3.12 (via UV)
- Rust (via rustup)
- Node.js & npm
- Go
- SSH (auto-start)
- Build tools

💡 Restart your terminal or run 'source /etc/profile' to apply changes.
${NC}"
