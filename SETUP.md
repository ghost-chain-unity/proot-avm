# proot-avm Setup Guide

## 📋 Table of Contents

- [Installation](#installation)
- [Post-Installation Setup](#post-installation-setup)
- [Usage](#usage)
- [Development Environment](#development-environment)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)
- [Script Organization](#script-organization)

## Installation

### Method 1: One-Command Install (Recommended)

```bash
curl -fsSL https://alpinevm.qzz.io/install | bash
```

This command:
1. Auto-detects the best installation method (GitHub Pages or raw GitHub)
2. Downloads the complete repository with all scripts
3. Installs all dependencies (proot-distro, QEMU, etc.)
4. Sets up Alpine Linux VM with development environment
5. Installs Go CLI and Bash scripts
6. Configures `avm` command with auto-completion

### Method 2: Binary Download (Fastest)

Download pre-compiled binaries from [GitHub Releases](https://github.com/ghost-chain-unity/proot-avm/releases):

```bash
# Linux x86_64
wget https://github.com/ghost-chain-unity/proot-avm/releases/download/v2.0.0/avm-linux-amd64.tar.gz
tar -xzf avm-linux-amd64.tar.gz
sudo mv avm /usr/local/bin/

# Android/Termux
wget https://github.com/ghost-chain-unity/proot-avm/releases/download/v2.0.0/avm-android-arm64.tar.gz
tar -xzf avm-android-arm64.tar.gz
mv avm ~/bin/  # or add to PATH
```

### Method 3: Manual Installation

```bash
# Clone repository
git clone https://github.com/ghost-chain-unity/proot-avm.git
cd proot-avm

# Run installer with development environment
./install.sh --agent

# Or install system-wide
sudo ./install.sh --system
```

### Method 4: Package Manager (Arch Linux)

```bash
# Clone and build package
git clone https://github.com/ghost-chain-unity/proot-avm.git
cd proot-avm
makepkg -si
```

## Post-Installation Setup

After installation completes, follow these steps:

### 1. Setup Alpine Linux (One-time)

```bash
avm first-boot
```

This will:
- Start Alpine VM with installation ISO
- Automatically run `setup-alpine` with generated credentials
- Configure SSH and basic services

**Important**: Save the generated password shown during setup!

### 2. Start the VM

```bash
avm start
```

Starts the VM in console mode. Wait for boot to complete (~1-2 minutes).

### 3. Connect via SSH

```bash
avm ssh
```

Connects to the VM using SSH on port 2222.

## Usage

### Basic VM Commands

```bash
# Start VM
avm start [mode] [ports]

# Stop VM
avm stop

# Restart VM
avm restart

# Check status
avm status

# SSH into VM
avm ssh

# Execute command in VM
avm exec "docker ps"

# Monitor VM logs
avm monitor
```

### Advanced VM Management

```bash
# Create snapshot
avm snap create my-snapshot

# List snapshots
avm snap list

# Restore snapshot
avm snap restore my-snapshot

# Backup VM disk
avm backup backup.img

# Resize disk
avm resize +5G

# Configure VM settings
avm configure
```

### Modes

- `console` (default): Interactive console
- `vnc`: VNC server mode
- `headless`: Background mode

## Development Environment

The VM comes pre-configured with:

### Core Tools
- **Docker & Docker Compose** - Container management
- **containerd** - Container runtime

### Programming Languages
- **Python 3.12.11** - Via UV package manager
- **Rust** - Via rustup
- **Node.js & npm** - JavaScript runtime
- **Go** - Go programming language

### Development Tools
- **UV** - Fast Python package manager
- **OpenHands** - AI-powered development assistant
- **Git** - Version control
- **Make, CMake** - Build systems
- **Clang, GCC** - Compilers
- **SSH Server** - Remote access

### Environment Setup

Inside the VM, the following are configured:

```bash
# PATH includes
export PATH=$PATH:$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.uv/bin

# Cargo (Rust) environment
source $HOME/.cargo/env

# UV environment
export UV_HOME=$HOME/.uv
```

## Troubleshooting

### VM Won't Start

```bash
# Check VM status
avm status

# Check logs
tail -f ~/qemu-vm/alpine-vm.log

# Restart terminal and try again
source ~/.bashrc
avm start
```

### SSH Connection Fails

```bash
# Check if VM is running
avm status

# Wait longer for boot (SSH takes ~1-2 minutes)
sleep 120
avm ssh

# Check SSH port
netstat -tlnp | grep 2222
```

### Docker Not Working

```bash
# Inside VM, check Docker status
service docker status

# Start Docker if needed
service docker start

# Add user to docker group (if needed)
adduser $USER docker
```

### Permission Issues

```bash
# Fix script permissions
chmod +x ~/qemu-vm/alpine-vm.sh
chmod +x ~/alpine-start.sh

# Update PATH
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc
source ~/.bashrc
```

### Reset VM

```bash
# Stop VM
avm stop

# Remove VM disk (WARNING: loses all data)
rm ~/qemu-vm/alpine-docker.img

# Re-run setup
avm first-boot
```

## Advanced Configuration

### AI Configuration

proot-avm supports multiple AI providers for intelligent assistance. Configure your preferred provider:

#### OpenAI (Cloud)
```bash
export OPENAI_API_KEY="your-openai-api-key"
export AVM_AI_PROVIDER="openai"
```

#### Claude (Anthropic)
```bash
export ANTHROPIC_API_KEY="your-anthropic-api-key"
export AVM_AI_PROVIDER="claude"
```

#### Ollama (Local)
```bash
# Install Ollama first
curl -fsSL https://ollama.ai/install.sh | sh

# Pull a model
ollama pull llama2

# Configure proot-avm
export AVM_AI_PROVIDER="ollama"
```

#### OpenHands (Local AI Coding Assistant)
```bash
# Install OpenHands
pip install openhands

# Configure proot-avm
export AVM_AI_PROVIDER="openhands"
```

#### Environment Variables
Add to your `~/.bashrc` or `~/.zshrc`:
```bash
# AI Provider Configuration
export AVM_AI_PROVIDER="ollama"  # openai, claude, ollama, openhands
export OPENAI_API_KEY=""
export ANTHROPIC_API_KEY=""
```

### VM Settings

Edit `~/.alpine-vm.conf`:

```bash
VM_RAM=4096          # RAM in MB
VM_CPU=4            # CPU cores
SSH_PORT=2222       # SSH port
VNC_PORT=5901       # VNC port
```

### Custom Installation

```bash
# Install without agent (basic setup)
./install.sh

# Custom domain
INSTALL_URL=https://custom.domain/install.sh ./install-one-liner.sh

# Custom options
INSTALL_OPTS="--help" ./install-one-liner.sh
```

### Port Forwarding

```bash
# Forward web server port
avm start headless 8080-:80

# Forward multiple ports
avm start headless 8080-:80,8443-:443
```

## Script Organization

### Recommended Scripts
- **`scripts/install/install.sh`** - Main installer
- **`scripts/install/install-one-liner.sh`** - One-liner installer
- **`scripts/core/avm-go.sh`** - Go CLI launcher
- **`scripts/core/dashboard-v2.sh`** - Web dashboard
- **`scripts/core/tui.sh`** - Terminal UI

### Legacy Scripts (Deprecated)
- **`install-agent.sh`** → Use `scripts/install/install.sh --agent`
- **`setup-wizard.sh`** → Use `scripts/setup-wizard-enhanced.sh`
- **`alpine-bootstrap.sh`** → Use `scripts/enhanced-bootstrap.sh`

**Note**: Legacy scripts show deprecation warnings and are maintained as symlinks.

### File Structure

```
proot-avm/
├── scripts/                   # Organized scripts
│   ├── install/               # Installation scripts
│   │   ├── install.sh         # Main installer
│   │   ├── install-one-liner.sh # One-liner installer
│   │   └── install-agent.sh   # Agent installer
│   ├── core/                  # Core functionality
│   │   ├── avm-go.sh          # Go CLI launcher
│   │   ├── dashboard-v2.sh    # Web dashboard
│   │   └── tui.sh             # Terminal UI
│   └── utils/                 # Utilities
│       ├── docs.sh            # Documentation viewer
│       ├── build-binaries.sh  # Binary builder
│       └── test-*.sh          # Test scripts
├── *.sh                       # Symlinks for compatibility
├── PKGBUILD                   # Arch Linux package
├── README.md                  # Welcome & overview
├── SETUP.md                   # This detailed guide
├── configs/                   # Configuration files
│   ├── alpine-answers.txt     # Alpine setup answers
│   └── sshd_config           # SSH configuration
└── docs/                      # Web documentation
    ├── index.html             # GitHub Pages site
    └── CNAME                  # Custom domain
```

## Development

### Building from Source

```bash
git clone https://github.com/ghost-chain-unity/proot-avm.git
cd proot-avm
./install.sh --agent
```

### Testing

```bash
# Test installer
./install.sh --help

# Test VM commands
avm help

# Check script syntax
bash -n scripts/*.sh
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

- **Issues**: [GitHub Issues](https://github.com/ghost-chain-unity/proot-avm/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ghost-chain-unity/proot-avm/discussions)

## License

This project is licensed under the MIT License - see the LICENSE file for details.