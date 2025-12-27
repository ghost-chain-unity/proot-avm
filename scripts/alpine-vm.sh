
#!/data/data/com.termux/files/usr/bin/bash

# ═══════════════════════════════════════════════════════════
#  ALPINE VM MANAGER - ULTIMATE EDITION
#  Full-Featured QEMU Management with Advanced Controls
# ═══════════════════════════════════════════════════════════

VM_DIR="$HOME/qemu-vm"
VM_IMG="alpine-docker.img"
VM_RAM="${VM_RAM:-2048}"
VM_CPU="${VM_CPU:-2}"
SSH_PORT="${SSH_PORT:-2222}"
VNC_PORT="${VNC_PORT:-5901}"
CONFIG_FILE="$HOME/.alpine-vm.conf"
PID_FILE="/tmp/alpine-vm.pid"
LOG_FILE="$VM_DIR/alpine-vm.log"

# Colors
RED=$'\e[0;31m'
GREEN=$'\e[0;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[0;34m'
MAGENTA=$'\e[0;35m'
CYAN=$'\e[0;36m'
NC=$'\e[0m' # No Color

# Load config
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

# Save config
save_config() {
    cat > "$CONFIG_FILE" << EOF
VM_RAM=$VM_RAM
VM_CPU=$VM_CPU
SSH_PORT=$SSH_PORT
VNC_PORT=$VNC_PORT
EOF
    echo -e "${GREEN}✅ Configuration saved${NC}"
}

# Log function
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if VM is running
is_running() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        return 0
    fi
    return 1
}

# Port forward builder
build_port_forwards() {
    local forwards="hostfwd=tcp::${SSH_PORT}-:22"

    # Additional port forwards from arguments
    shift
    while [ $# -gt 0 ]; do
        forwards="${forwards},hostfwd=tcp::$1"
        shift
    done

    echo -e "$forwards"
}

# Start VM with advanced options
start_vm() {
    if is_running; then
        echo -e "${YELLOW}⚠️  VM is already running (PID: $(cat $PID_FILE))${NC}"
        return 1
    fi

    local mode="${1:-console}"
    local extra_ports="${2}"

    echo -e "${CYAN}🚀 Starting Alpine VM in $mode mode...${NC}"
    log "Starting VM: mode=$mode, RAM=${VM_RAM}MB, CPU=$VM_CPU"

    local qemu_cmd="cd $VM_DIR && nohup qemu-system-x86_64 \
        -m $VM_RAM \
        -smp $VM_CPU \
        -hda $VM_IMG \
        -enable-kvm 2>/dev/null || true \
        -cpu host 2>/dev/null || -cpu max \
        -net nic,model=virtio \
        -net user,$(build_port_forwards $extra_ports) \
        -device virtio-rng-pci"

    case "$mode" in
        console|nographic)
            qemu_cmd="$qemu_cmd -nographic"
            ;;
        vnc)
            qemu_cmd="$qemu_cmd -vnc :1 -k en-us"
            echo -e "${BLUE}📺 VNC available at: localhost:$VNC_PORT${NC}"
            ;;
        headless)
            qemu_cmd="$qemu_cmd -display none"
            ;;
        *)
            echo -e "${RED}❌ Unknown mode: $mode${NC}"
            return 1
            ;;
    esac

    # Add monitor socket
    qemu_cmd="$qemu_cmd -monitor unix:/tmp/qemu-monitor.sock,server,nowait"

    # Run in background
    proot-distro login ubuntu --termux-home -- sh -c "$qemu_cmd > '$LOG_FILE' 2>&1 & echo \$! > '$PID_FILE'"

    sleep 2

    if is_running; then
        echo -e "${GREEN}✅ VM started successfully (PID: $(cat $PID_FILE))${NC}"
        echo -e "${BLUE}📝 Logs: tail -f $LOG_FILE${NC}"
        log "VM started successfully"
    else
        echo -e "${RED}❌ Failed to start VM. Check logs: $LOG_FILE${NC}"
        log "Failed to start VM"
    fi
}

# Stop VM gracefully
stop_vm() {
    if ! is_running; then
        echo -e "${YELLOW}⚠️  VM is not running${NC}"
        return 1
    fi

    echo -e "${YELLOW}⏹️  Stopping Alpine VM gracefully...${NC}"

    # Try ACPI shutdown first
    echo -e "system_powerdown" | nc -U /tmp/qemu-monitor.sock 2>/dev/null || true

    # Wait for graceful shutdown
    for i in {1..30}; do
        if ! is_running; then
            echo -e "${GREEN}✅ VM stopped gracefully${NC}"
            rm -f "$PID_FILE"
            log "VM stopped gracefully"
            return 0
        fi
        sleep 1
    done

    # Force kill if still running
    echo -e "${RED}⚠️  Force killing VM...${NC}"
    kill -9 $(cat "$PID_FILE") 2>/dev/null
    rm -f "$PID_FILE"
    log "VM force killed"
}

# Restart VM
restart_vm() {
    echo -e "${CYAN}🔄 Restarting VM...${NC}"
    stop_vm
    sleep 2
    start_vm "$@"
}

# SSH into VM
ssh_vm() {
    if ! is_running; then
        echo -e "${RED}❌ VM is not running${NC}"
        return 1
    fi

    echo -e "${CYAN}🔐 Connecting via SSH (port $SSH_PORT)...${NC}"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $SSH_PORT root@localhost
}

# Execute command in VM via SSH
exec_vm() {
    if [ -z "$1" ]; then
        echo -e "${RED}❌ No command specified${NC}"
        return 1
    fi

    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $SSH_PORT root@localhost "$@"
}

# Snapshot management
snapshot_create() {
    local name="${1:-snapshot-$(date +%Y%m%d-%H%M%S)}"
    echo -e "${CYAN}📸 Creating snapshot: $name${NC}"

    proot-distro login ubuntu --termux-home -- bash -c "
        cd $VM_DIR && qemu-img snapshot -c '$name' $VM_IMG
    "

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Snapshot created: $name${NC}"
        log "Snapshot created: $name"
    else
        echo -e "${RED}❌ Failed to create snapshot${NC}"
    fi
}

snapshot_list() {
    echo -e "${CYAN}📋 Available snapshots:${NC}"
    proot-distro login ubuntu --termux-home -- bash -c "
        cd $VM_DIR && qemu-img snapshot -l $VM_IMG
    "
}

snapshot_restore() {
    if [ -z "$1" ]; then
        echo -e "${RED}❌ Snapshot name required${NC}"
        snapshot_list
        return 1
    fi

    if is_running; then
        echo -e "${YELLOW}⚠️  Stopping VM before restore...${NC}"
        stop_vm
        sleep 2
    fi

    echo -e "${CYAN}♻️  Restoring snapshot: $1${NC}"
    proot-distro login ubuntu --termux-home -- bash -c "
        cd $VM_DIR && qemu-img snapshot -a '$1' $VM_IMG
    "

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Snapshot restored: $1${NC}"
        log "Snapshot restored: $1"
        echo -e "${BLUE}💡 Start VM with: avm start${NC}"
    else
        echo -e "${RED}❌ Failed to restore snapshot${NC}"
    fi
}

snapshot_delete() {
    if [ -z "$1" ]; then
        echo -e "${RED}❌ Snapshot name required${NC}"
        return 1
    fi

    echo -e "${YELLOW}🗑️  Deleting snapshot: $1${NC}"
    proot-distro login ubuntu --termux-home -- bash -c "
        cd $VM_DIR && qemu-img snapshot -d '$1' $VM_IMG
    "

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Snapshot deleted: $1${NC}"
    fi
}

# Backup/Clone VM
backup_vm() {
    local backup_name="${1:-alpine-backup-$(date +%Y%m%d-%H%M%S).img}"
    echo -e "${CYAN}💾 Creating backup: $backup_name${NC}"

    proot-distro login ubuntu --termux-home -- bash -c "
        cd $VM_DIR && cp -v $VM_IMG '$backup_name'
    "

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Backup created: $backup_name${NC}"
        log "Backup created: $backup_name"
    fi
}

# Resize disk
resize_disk() {
    if [ -z "$1" ]; then
        echo -e "${RED}❌ Size required (e.g., +5G)${NC}"
        return 1
    fi

    if is_running; then
        echo -e "${RED}❌ Stop VM before resizing${NC}"
        return 1
    fi

    echo -e "${CYAN}📏 Resizing disk: $1${NC}"
    proot-distro login ubuntu --termux-home -- bash -c "
        cd $VM_DIR && qemu-img resize $VM_IMG '$1'
    "

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Disk resized${NC}"
        echo -e "${YELLOW}⚠️  Don't forget to resize partition inside VM!${NC}"
    fi
}

# Status and monitoring
status_vm() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${MAGENTA}   ALPINE VM STATUS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"

    if is_running; then
        local pid=$(cat "$PID_FILE")
        echo -e "${GREEN}Status:${NC} RUNNING ✅"
        echo -e "${GREEN}PID:${NC} $pid"
        echo -e "${GREEN}Uptime:${NC} $(ps -p $pid -o etime= 2>/dev/null | xargs)"
        echo -e "${GREEN}Memory:${NC} ${VM_RAM}MB"
        echo -e "${GREEN}CPU:${NC} ${VM_CPU} cores"
        echo -e "${GREEN}SSH Port:${NC} $SSH_PORT"

        # Check SSH connectivity
        if nc -z localhost $SSH_PORT 2>/dev/null; then
            echo -e "${GREEN}SSH:${NC} Available ✅"
        else
            echo -e "${YELLOW}SSH:${NC} Not ready yet ⏳"
        fi
    else
        echo -e "${RED}Status:${NC} STOPPED ❌"
    fi

    echo -e "${CYAN}═══════════════════════════════════════${NC}"
}

# VM info
info_vm() {
    echo -e "${CYAN}ℹ️  VM Disk Information:${NC}"
    proot-distro login ubuntu --termux-home -- bash -c "
        cd $VM_DIR && qemu-img info $VM_IMG
    "
}

# Monitor VM (live stats)
monitor_vm() {
    if ! is_running; then
        echo -e "${RED}❌ VM is not running${NC}"
        return 1
    fi

    echo -e "${CYAN}📊 Monitoring VM (Ctrl+C to stop)...${NC}"
    echo -e "${BLUE}Logs:${NC}"
    tail -f "$LOG_FILE"
}

# Interactive console to PRoot
console_proot() {
    echo -e "${CYAN}🖥️  Entering PRoot Ubuntu console...${NC}"
    proot-distro login ubuntu --termux-home -- bash -c "cd $VM_DIR && exec bash"
}

# Configure VM
configure_vm() {
    echo -e "${CYAN}⚙️  VM Configuration${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"

    read -p "RAM (MB) [$VM_RAM]: " new_ram
    [ -n "$new_ram" ] && VM_RAM=$new_ram

    read -p "CPU cores [$VM_CPU]: " new_cpu
    [ -n "$new_cpu" ] && VM_CPU=$new_cpu

    read -p "SSH port [$SSH_PORT]: " new_ssh
    [ -n "$new_ssh" ] && SSH_PORT=$new_ssh

    read -p "VNC port [$VNC_PORT]: " new_vnc
    [ -n "$new_vnc" ] && VNC_PORT=$new_vnc

    save_config
}

# Install Docker in VM
install_docker() {
    echo -e "${CYAN}🐳 Installing Docker in VM..."

    if ! is_running; then
        echo -e "${RED}❌ VM must be running${NC}"
        return 1
    fi

    exec_vm "apk update && apk add docker docker-compose && rc-update add docker boot && service docker start && docker --version"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Docker installed successfully${NC}"
    fi
}

# Show help
show_help() {
    cat << EOF
${MAGENTA}╔═══════════════════════════════════════════════════════════╗
║         ALPINE VM MANAGER - ULTIMATE EDITION              ║
║                  Full-Featured QEMU Control                ║
╚═══════════════════════════════════════════════════════════╝${NC}

${CYAN}USAGE:${NC} avm [command] [options]

${CYAN}VM CONTROL:${NC}
  ${GREEN}start [mode] [ports]${NC}   Start VM (console|vnc|headless)
                          Ports: 8080-:80,8443-:443
  ${GREEN}stop${NC}                  Stop VM gracefully
  ${GREEN}restart [mode]${NC}        Restart VM
  ${GREEN}status${NC}                Show VM status
  ${GREEN}monitor${NC}               Monitor VM logs (live)

${CYAN}CONNECTION:${NC}
  ${GREEN}ssh${NC}                   SSH into VM
  ${GREEN}exec <cmd>${NC}            Execute command in VM

${CYAN}SNAPSHOTS:${NC}
  ${GREEN}snap [name]${NC}           Create snapshot
  ${GREEN}snap-list${NC}             List snapshots
  ${GREEN}snap-restore <name>${NC}   Restore snapshot
  ${GREEN}snap-delete <name>${NC}    Delete snapshot

${CYAN}MANAGEMENT:${NC}
  ${GREEN}backup [name]${NC}         Backup VM image
  ${GREEN}resize <size>${NC}         Resize disk (e.g., +5G)
  ${GREEN}info${NC}                  Show disk info
  ${GREEN}config${NC}                Configure VM settings
  ${GREEN}console${NC}               Enter PRoot Ubuntu shell

${CYAN}DOCKER:${NC}
  ${GREEN}docker-install${NC}        Install Docker in VM

${CYAN}EXAMPLES:${NC}
  avm start                    # Start in console mode
  avm start vnc                # Start with VNC
  avm start headless 8080-:80  # Headless with port forward
  avm ssh                      # Connect via SSH
  avm exec "docker ps"         # Run command in VM
  avm snap before-update       # Create snapshot
  avm snap-restore before-update
  avm resize +5G               # Add 5GB to disk

${CYAN}CONFIG FILE:${NC} $CONFIG_FILE
${CYAN}LOG FILE:${NC} $LOG_FILE
${CYAN}PID FILE:${NC} $PID_FILE

${YELLOW}💡 TIP: Use 'avm monitor' to watch live logs${NC}
EOF
}

# Main script
load_config

case "$1" in
    start) start_vm "${2:-console}" "${@:3}" ;;
    stop) stop_vm ;;
    restart) restart_vm "${2:-console}" "${@:3}" ;;
    ssh) ssh_vm ;;
    exec) shift; exec_vm "$@" ;;
    snap|snapshot) snapshot_create "$2" ;;
    snap-list|snapshots) snapshot_list ;;
    snap-restore) snapshot_restore "$2" ;;
    snap-delete) snapshot_delete "$2" ;;
    backup) backup_vm "$2" ;;
    resize) resize_disk "$2" ;;
    status) status_vm ;;
    info) info_vm ;;
    monitor|logs) monitor_vm ;;
    console) console_proot ;;
    config|configure) configure_vm ;;
    docker-install) install_docker ;;
    help|--help|-h) show_help ;;
    *)
        if [ -z "$1" ]; then
            show_help
        else
            echo -e "${RED}❌ Unknown command: $1${NC}"
            echo -e "${YELLOW}💡 Use 'avm help' for usage${NC}"
        fi
        ;;
esac
