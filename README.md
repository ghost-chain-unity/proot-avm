
# proot-avm - Alpine VM Manager for Termux

[![CI/CD](https://github.com/ghost-chain-unity/proot-avm/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/ghost-chain-unity/proot-avm/actions/workflows/ci-cd.yml)
[![Go Report Card](https://goreportcard.com/badge/github.com/ghost-chain-unity/proot-avm)](https://goreportcard.com/report/github.com/ghost-chain-unity/proot-avm)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🚀 What is proot-avm?

proot-avm is a modern Alpine Linux VM manager for Termux that provides a complete development environment with Docker support. It automates the setup of QEMU virtual machines with pre-configured development tools.

## ✨ Key Features

- 🐧 **Alpine Linux VM** with automated setup
- 🐳 **Docker & Docker Compose** ready to use
- 🛠️ **Full Dev Stack**: Python, Rust, Node.js, Go, UV, OpenHands
- 🤖 **AI-Powered Assistant** with multiple providers (OpenAI, Claude, Ollama, OpenHands)
- ⚡ **One-command installation** via curl
- 🎛️ **Comprehensive VM management** with `avm` command
- 📸 **Snapshot & backup** functionality
- 🔒 **Secure SSH access** with generated credentials
- 🌐 **Modern Web Dashboard** with real-time monitoring
- 🖥️ **Terminal UI (TUI)** with Bubbletea interface

## 🏁 Quick Start

### Option 1: One-Liner Install (Recommended)
```bash
curl -fsSL https://alpinevm.qzz.io/install | bash
```
**What's included:** Complete installation with all scripts, Go CLI, web dashboard, TUI, and documentation.

### Option 2: Development Setup
```bash
# Clone repository
git clone https://github.com/ghost-chain-unity/proot-avm.git
cd proot-avm

# Install development dependencies
make dev-setup

# Or manually
./scripts/install/install.sh --dev
```

### Option 2: Binary Download (Fastest)
Download pre-compiled binaries for your platform:

#### Linux/Android (arm64)
```bash
# Download and install
curl -fsSL https://github.com/ghost-chain-unity/proot-avm/releases/download/v2.0.0/install-linux-arm64.sh | sh
```

#### Linux (amd64)
```bash
curl -fsSL https://github.com/ghost-chain-unity/proot-avm/releases/download/v2.0.0/install-linux-amd64.sh | sh
```

#### macOS (Intel)
```bash
curl -fsSL https://github.com/ghost-chain-unity/proot-avm/releases/download/v2.0.0/install-darwin-amd64.sh | sh
```

#### macOS (Apple Silicon)
```bash
curl -fsSL https://github.com/ghost-chain-unity/proot-avm/releases/download/v2.0.0/install-darwin-arm64.sh | sh
```

#### Windows
```bash
curl -fsSL https://github.com/ghost-chain-unity/proot-avm/releases/download/v2.0.0/install-windows-amd64.sh | sh
```

### Option 3: Manual Installation
```bash
# Clone repository
git clone https://github.com/ghost-chain-unity/proot-avm.git
cd proot-avm

# Run installer
./install.sh --agent
```

## 📚 Documentation

- **[Setup Guide](SETUP.md)** - Detailed installation and configuration
- **[Development Guide](DEVELOPMENT.md)** - Development environment and workflow
- **[Contributing Guide](CONTRIBUTING.md)** - How to contribute to the project
- **[Roadmap](ROADMAP.md)** - Future development plans
- **[GitHub Repository](https://github.com/ghost-chain-unity/proot-avm)** - Source code and issues

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for detailed information on how to get started.

For development setup, check out our [Development Guide](DEVELOPMENT.md).

---

**Made with ❤️ for Termux developers**

Licensed under [MIT License](LICENSE)

## 🤖 AI Assistant

proot-avm includes a powerful AI-powered assistant that can help you with VM management, Docker operations, troubleshooting, and development tasks.

### AI Providers Supported

- **OpenAI GPT** - Cloud-based AI with GPT models
- **Claude (Anthropic)** - Advanced AI assistant
- **Ollama** - Local AI models (Llama, Mistral, etc.)
- **OpenHands** - AI coding assistant with local execution

### Configuration

Set your preferred AI provider:

```bash
# OpenAI (requires API key)
export OPENAI_API_KEY="your-api-key-here"
export AVM_AI_PROVIDER="openai"

# Claude (requires API key)
export ANTHROPIC_API_KEY="your-api-key-here"
export AVM_AI_PROVIDER="claude"

# Ollama (local, no API key needed)
export AVM_AI_PROVIDER="ollama"

# OpenHands (local installation required)
export AVM_AI_PROVIDER="openhands"
```

### Usage Examples

```bash
# Get help with Docker
avm-go ai-assist --query "How do I run a Docker container?"

# Troubleshoot VM issues
avm-go ai-assist --query "VM won't start, what should I check?"

# Development assistance
avm-go ai-assist --query "Set up a Node.js development environment"
```

### AI in Web Dashboard

The web dashboard includes an AI chat interface accessible at `/dashboard` with real-time AI assistance for:
- VM management commands
- Docker operations
- Troubleshooting guides
- Development setup

### AI in Terminal UI

The TUI includes an AI Assistant menu option for interactive help within the terminal interface.

## Usage

### First Time Setup
After installation, run the automated first boot setup:
```bash
# Modern Go CLI (Recommended)
avm-go first-boot

# Or legacy CLI
avm first-boot
```
This will automatically configure Alpine Linux with generated credentials.

### Available Interfaces

#### Modern Go CLI (Recommended)
```bash
avm-go start         # Start VM with advanced options
avm-go stop          # Stop VM gracefully
avm-go status        # Check VM status with metrics
avm-go ssh           # SSH with auto-completion
avm-go dashboard     # Launch web dashboard
avm-go tui          # Launch terminal UI
avm-go monitor      # Real-time performance monitoring
avm-go ai-assist    # Get AI-powered help
avm-go --help       # Show all commands
```

#### Legacy CLI (Still Supported)
```bash
avm start           # Start VM
avm ssh             # SSH into VM
avm help            # Show legacy commands
```

#### Additional Tools
```bash
avm-docs           # Launch documentation website
```

### Basic VM Control
```bash
# Start VM
avm-go start

# SSH into VM
avm-go ssh

# Check status with metrics
avm-go status --json

# Launch web dashboard
avm-go dashboard
```

# Show help
avm help
```

### Development Environment
The VM comes pre-configured with:
- Docker & Docker Compose
- Python 3.12.11 (via UV)
- Rust (via rustup)
- Node.js & npm
- Go
- Build tools (make, cmake, clang, glibc)
- OpenHands AI assistant
- SSH server (port 2222)

### Endpoint Details
- **Main URL**: `https://raw.githubusercontent.com/ghost-chain-unity/proot-avm/main/install-one-liner.sh` → serves the complete one-liner installer
- **Installer URL**: `https://raw.githubusercontent.com/ghost-chain-unity/proot-avm/main/install.sh` → serves the main installer
- **Scripts URL**: `https://raw.githubusercontent.com/ghost-chain-unity/proot-avm/main/scripts/` → serves additional scripts

**Note**: URLs are flexible and can be changed by setting environment variables:
- `INSTALL_URL` for custom installer location
- `INSTALL_OPTS` for custom installer options

## Login Information

After first boot setup, you'll get:
- **Hostname**: alpine-vm
- **Username**: root
- **Password**: Randomly generated (shown during setup)
- **SSH Port**: 2222 (from Termux host)

## Script Organization

### Recommended Scripts
- **`install.sh`** - Main installer (use with `--agent` for full setup)
- **`install-one-liner.sh`** - One-liner installer (downloads install.sh)
- **`scripts/avm-agent.sh`** - Automated dev environment setup (runs inside VM)
- **`scripts/enhanced-bootstrap.sh`** - Enhanced bootstrap (alternative to avm-agent.sh)
- **`scripts/alpine-vm.sh`** - VM management tool
- **`scripts/setup-alpine-auto.sh`** - Automated Alpine setup-alpine

### Legacy Scripts (Deprecated)
- **`install-agent.sh`** → Use `install.sh --agent`
- **`setup-wizard.sh`** → Use `setup-wizard-enhanced.sh`
- **`alpine-bootstrap.sh`** → Use `enhanced-bootstrap.sh` or `avm-agent.sh`
- **`setup.sh`** → Use `install.sh`

**Note:** Legacy scripts will show deprecation warnings and may be removed in future versions.

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
