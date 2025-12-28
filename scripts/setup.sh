
#!/usr/bin/env bash

# Setup script for proot-avm
echo "🛠️ Setting up Alpine VM Manager..."

# Determine script directory (repo-relative)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create VM directory
mkdir -p ~/qemu-vm

# Copy scripts to proper locations (use repo scripts when available)
cp "$SCRIPT_DIR/alpine-vm.sh" ~/qemu-vm/ 2>/dev/null || cp /usr/bin/alpine-vm.sh ~/qemu-vm/ 2>/dev/null || true
cp "$SCRIPT_DIR/alpine-start.sh" ~/alpine-start.sh 2>/dev/null || cp /usr/bin/alpine-start.sh ~/alpine-start.sh 2>/dev/null || true

# Set permissions
chmod +x ~/alpine-start.sh
chmod +x ~/qemu-vm/alpine-vm.sh

# Create alias
echo 'alias avm="~/alpine-start.sh"' >> ~/.bashrc

# Create user-local symlink (avoid requiring root)
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/qemu-vm/alpine-vm.sh" "$HOME/.local/bin/avm"
grep -qxF 'export PATH="$PATH:$HOME/.local/bin"' ~/.bashrc || echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc

echo "✅ Setup complete! You can now use 'avm' command."
