
#!/data/data/com.termux/files/usr/bin/bash

# Alpine VM Setup Wizard
# Interactive setup for proot-avm

echo -e "\e[1;34m
╔═══════════════════════════════════════════════════════════╗
║  ALPINE VM SETUP WIZARD                               ║
║  Full Docker + Dev Environment                        ║
╚═══════════════════════════════════════════════════════════╝
\e[0m"

# Step 1: Install proot-distro and setup Ubuntu environment
echo -e "\e[0;32m[1/5] Setting up proot-distro Ubuntu environment...\e[0m"
pkg install -y proot-distro
proot-distro install ubuntu
proot-distro login ubuntu --termux-home -- bash -c "
    apt-get update && apt-get install -y wget curl qemu-utils
"
echo -e "\e[0;32m✅ proot-distro Ubuntu environment ready\e[0m"

# Step 2: Download Alpine ISO
echo -e "\e[0;32m[2/5] Downloading Alpine Linux ISO...\e[0m"
mkdir -p ~/qemu-vm
cd ~/qemu-vm
wget -q --show-progress https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-virt-3.18.0-x86_64.iso -O alpine.iso
echo -e "\e[0;32m✅ Alpine ISO downloaded\e[0m"

# Step 3: Create VM disk image
echo -e "\e[0;32m[3/5] Creating virtual disk (10GB)...\e[0m"
proot-distro login ubuntu --termux-home -- bash -c "
    cd ~/qemu-vm && qemu-img create -f qcow2 alpine-docker.img 10G
"
echo -e "\e[0;32m✅ Virtual disk created\e[0m"

# Step 4: First boot - Alpine setup
echo -e "\e[0;32m[4/5] First boot - Alpine setup required\e[0m"
echo -e "\e[1;33mPlease follow the prompts in the VM console...\e[0m"

# Start VM for initial setup
proot-distro login ubuntu --termux-home -- bash -c "
    cd ~/qemu-vm && qemu-system-x86_64 -m 2048 -smp 2 -hda alpine-docker.img -cdrom alpine.iso -boot d -nographic
"

echo -e "\e[0;32m✅ Initial Alpine setup complete\e[0m"

# Step 5: Install development environment
echo -e "\e[0;32m[5/5] Installing development environment...\e[0m"

# Copy bootstrap script to VM
proot-distro login ubuntu --termux-home -- bash -c "
    cd ~/qemu-vm && cp /usr/bin/alpine-bootstrap.sh .
    chmod +x alpine-bootstrap.sh
    ./alpine-bootstrap.sh
"
echo -e "\e[0;32m✅ Development environment installed\e[0m"

# Step 6: Install AVM management tool
echo -e "\e[0;32m[6/6] Installing AVM management tool...\e[0m"

# Use script directory when running from source tree
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cp "$SCRIPT_DIR/alpine-vm.sh" ~/qemu-vm/ 2>/dev/null || cp /usr/bin/alpine-vm.sh ~/qemu-vm/ 2>/dev/null || true
chmod +x ~/qemu-vm/alpine-vm.sh
ln -sf ~/qemu-vm/alpine-vm.sh /usr/bin/avm

# Step 7: Configure bashrc and environment
echo -e "\e[0;32m[7/7] Configuring bashrc and environment...\e[0m"

# Add alias to Termux bashrc
echo 'alias avm="~/alpine-start.sh"' >> ~/.bashrc

# Add alias to proot-distro bashrc
proot-distro login ubuntu --termux-home -- bash -c "
    echo 'alias avm=\"~/alpine-vm.sh\"' >> ~/.bashrc
    echo 'export PATH=\$PATH:~/qemu-vm' >> ~/.bashrc
"

# Make scripts executable in proot-distro
proot-distro login ubuntu --termux-home -- bash -c "
    chmod +x ~/alpine-vm.sh
    chmod +x ~/qemu-vm/alpine-vm.sh
"

echo -e "\e[1;34m
🎉 Setup complete!

Quick start:
  $ avm start    # Start Alpine VM
  $ avm ssh      # SSH into VM
  $ avm help     # Show all commands

💡 Note: Please restart your terminal or run 'source ~/.bashrc' to apply changes.
\e[0m"
