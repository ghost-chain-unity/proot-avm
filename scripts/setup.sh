
#!/data/data/com.termux/files/usr/bin/bash

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

# Create system-wide symlink
ln -sf ~/qemu-vm/alpine-vm.sh /usr/bin/avm

echo "✅ Setup complete! You can now use 'avm' command."
