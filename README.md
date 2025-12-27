
# proot-avm - Alpine VM Manager for Termux

## Description

proot-avm is a Termux package that provides an automated setup for running Alpine Linux VM with Docker support. It includes a comprehensive management tool for controlling QEMU virtual machines.

## Features

- One-command installation with `pkg install proot-avm`
- Automated setup of Alpine Linux VM
- Comprehensive VM management with `avm` command
- Docker support
- Snapshot management
- Backup/restore functionality
- Port forwarding and VNC support

## Installation

```bash
pkg install proot-avm
proot-avm-setup
```

## Usage

```bash
# Start VM
avm start

# SSH into VM
avm ssh

# Manage snapshots
avm snap create-snapshot
avm snap-list
avm snap-restore snapshot-name

# Show help
avm help
```

## Files

- `scripts/alpine-start.sh` - Termux side starter script
- `scripts/alpine-vm.sh` - Main VM management script
- `scripts/setup.sh` - Initial setup script
