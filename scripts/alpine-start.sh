
#!/data/data/com.termux/files/usr/bin/bash

# Alpine VM Starter - Termux Side
echo "🚀 Launching Alpine VM Manager..."
proot-distro login ubuntu --termux-home -- bash -c "cd ~/qemu-vm && ~/alpine-vm.sh $*"
