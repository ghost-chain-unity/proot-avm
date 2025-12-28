
#!/bin/sh
# DEPRECATED: Alpine Linux Bootstrap Script (Legacy)
# This script is deprecated. Use enhanced-bootstrap.sh or avm-agent.sh instead.
# Will be removed in future versions.

echo "⚠️  WARNING: This script is deprecated!"
echo "   Please use: enhanced-bootstrap.sh (inside VM)"
echo "   Or run: curl -sSL https://alpinevm.qzz.io/install | bash"
echo ""
echo "Continuing with legacy bootstrap..."

# Original code follows...

echo "🚀 Bootstrapping Alpine development environment..."

# Update repositories
setup-apkrepos -f

# Update system
apk update
apk upgrade

# Install core packages
apk add docker docker-cli-compose containerd build-base git curl wget

# Enable services
rc-update add docker boot
rc-update add containerd boot
service docker start

# Install UV (Python version manager)
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.cargo/env

# Install Python 3.12
uv python install 3.12
uv python pin 3.12

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Install Node.js
apk add nodejs npm

# SSH setup
apk add openssh
rc-update add sshd default
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
service sshd start

echo "✅ Bootstrap complete!"
