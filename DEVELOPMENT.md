# Development Guide

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Bash** (4.0+)
- **Git** (2.0+)
- **Go** (1.21+) - for CLI development
- **QEMU** (6.0+) - for VM testing
- **proot-distro** - for container testing
- **Docker** (optional) - for container development

### Development Setup

```bash
# Clone the repository
git clone https://github.com/ghost-chain-unity/proot-avm.git
cd proot-avm

# Make scripts executable
chmod +x *.sh scripts/*.sh

# Run development installer
./install.sh --dev

# Test basic functionality
./test-installer.sh
```

## 🏗️ Project Structure

```
proot-avm/
├── avm-go/                    # Go CLI application
│   ├── ai_service.go         # AI service with multi-provider support
│   ├── main.go               # CLI entry point
│   ├── main_test.go          # Unit tests
│   └── go.mod               # Go module file
├── scripts/                # All shell scripts (organized)
│   ├── install/            # Installation scripts
│   │   ├── install.sh
│   │   ├── install-one-liner.sh
│   │   └── install-agent.sh
│   ├── core/               # Core functionality scripts
│   │   ├── avm-go.sh       # Go CLI launcher
│   │   ├── dashboard-v2.sh # Web dashboard
│   │   └── tui.sh          # Terminal UI
│   └── utils/              # Utility scripts
│       ├── docs.sh
│       ├── build-binaries.sh
│       └── test-*.sh
├── configs/                   # Configuration templates
│   ├── alpine-answers.txt    # Alpine installation answers
│   └── sshd_config          # SSH server configuration
├── backup/                    # Legacy scripts (deprecated)
├── *.sh                       # Symlinks to organized scripts
├── PKGBUILD                   # Arch Linux package build
├── README.md                  # Project overview
├── SETUP.md                   # Installation and usage guide
├── DEVELOPMENT.md             # This development guide
├── CONTRIBUTING.md            # Contribution guidelines
├── ROADMAP.md                 # Future development roadmap
├── LICENSE                    # MIT license
└── test-installer.sh          # Test suite (legacy symlink)
```

## 🔧 Development Workflow

### 1. Choose Your Development Path

#### Option A: Full VM Development (Recommended)
```bash
# Install in development mode
./install.sh --dev

# Start development VM
avm start

# SSH into development environment
avm ssh
```

#### Option B: Local Development
```bash
# Install dependencies locally
./install.sh --local

# Work directly on host system
# (Limited testing capabilities)
```

### 2. Make Changes

#### Bash Scripts
- Follow POSIX shell standards
- Use `set -e` for error handling
- Include comprehensive error messages
- Test with `bash -n script.sh`

#### Go CLI
- Follow Go conventions
- Include unit tests
- Use `go fmt` for formatting
- Test with `go test`

#### AI Service Development
The AI service (`ai_service.go`) supports multiple AI providers:

- **OpenAI**: Requires `OPENAI_API_KEY` environment variable
- **Claude**: Requires `ANTHROPIC_API_KEY` environment variable  
- **Ollama**: Local AI models, no API key required
- **OpenHands**: Local AI coding assistant

```go
// Example AI service usage
ai := NewAIService()
response, err := ai.CallAI("openai", "How do I start a Docker container?")
```

**AI Development Guidelines:**
- Always provide fallback responses when APIs are unavailable
- Include provider detection and status checking
- Handle rate limits and API errors gracefully
- Test with multiple providers in CI/CD

### 3. Testing

#### Automated Testing
```bash
# Run full test suite
./test-installer.sh

# Test specific components
bash -n scripts/*.sh  # Syntax check
go test ./avm-go/...  # Go tests
```

#### Manual Testing
```bash
# Test VM functionality
avm start console
avm ssh
avm exec "docker ps"

# Test installation scripts
./install-one-liner.sh --dry-run
```

#### Cross-Platform Testing
```bash
# Build binaries for all platforms
./build-binaries.sh

# Test on different architectures
# (Requires appropriate hardware/emulation)
```

### 4. Code Quality

#### Linting and Formatting
```bash
# Bash scripts
shellcheck scripts/*.sh *.sh

# Go code
gofmt -d avm-go/
go vet ./avm-go/...

# Format code
gofmt -w avm-go/
```

#### Pre-commit Checks
```bash
# Run all quality checks
make check  # (if Makefile exists)

# Or manually
shellcheck scripts/*.sh *.sh
go fmt ./avm-go/
go vet ./avm-go/
go test ./avm-go/
```

## 🐛 Debugging

### VM Debugging
```bash
# Enable verbose logging
export AVM_DEBUG=1
avm start

# Check VM logs
tail -f ~/qemu-vm/alpine-vm.log

# Monitor QEMU process
ps aux | grep qemu
```

### Script Debugging
```bash
# Enable bash debugging
set -x
./install.sh

# Test individual functions
source scripts/shared-functions.sh
some_function "test"
```

### Network Debugging
```bash
# Check port forwarding
netstat -tlnp | grep :2222

# Test SSH connectivity
ssh -v -p 2222 localhost

# Check VM network
avm exec "ip addr show"
```

## 📦 Building and Packaging

### Binary Releases
```bash
# Build for all platforms
./build-binaries.sh

# Test specific platform
GOOS=linux GOARCH=amd64 go build -o avm avm-go/

# Create release archives
tar -czf avm-linux-amd64.tar.gz avm
```

### Package Building
```bash
# Arch Linux package
makepkg -f

# Debian package (future)
# dpkg-buildpackage

# RPM package (future)
# rpmbuild -ba proot-avm.spec
```

## 🔄 CI/CD

### GitHub Actions
The project uses GitHub Actions for:
- Automated testing on multiple platforms
- Binary building and release
- Code quality checks
- Documentation validation

### Local CI Simulation
```bash
# Run CI checks locally
./scripts/ci-check.sh

# Test on multiple shell versions
docker run --rm -v $(pwd):/app -w /app bash:4.4 ./test-installer.sh
docker run --rm -v $(pwd):/app -w /app bash:5.1 ./test-installer.sh
```

## 🎯 Development Guidelines

### Code Style

#### Bash Scripts
```bash
#!/usr/bin/env bash
set -euo pipefail  # Strict mode

# Use descriptive variable names
readonly SCRIPT_NAME="${0##*/}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function declarations
main() {
    local arg="$1"

    validate_input "$arg"
    process_data "$arg"
}

validate_input() {
    local input="$1"

    if [[ -z "$input" ]]; then
        error_exit "Input cannot be empty"
    fi
}

error_exit() {
    local message="$1"
    echo "ERROR: $message" >&2
    exit 1
}

# Main execution
main "$@"
```

#### Go Code
```go
package main

import (
    "fmt"
    "os"
)

// Use meaningful names
type VMManager struct {
    config *Config
}

// Error handling
func (vm *VMManager) StartVM() error {
    if err := vm.validateConfig(); err != nil {
        return fmt.Errorf("failed to validate config: %w", err)
    }

    // Implementation
    return nil
}

func main() {
    if len(os.Args) < 2 {
        fmt.Println("Usage: avm <command>")
        os.Exit(1)
    }

    // Parse commands and execute
}
```

### Commit Messages
```
feat: add new VM snapshot feature
fix: resolve SSH connection timeout issue
docs: update installation instructions
refactor: simplify VM startup logic
test: add unit tests for VM manager
```

### Branch Naming
```
feature/add-snapshot-support
bugfix/ssh-timeout-issue
docs/update-readme
refactor/vm-startup-logic
```

## 🧪 Testing Strategy

### Unit Tests
- Test individual functions in isolation
- Mock external dependencies
- Cover edge cases and error conditions

### Integration Tests
- Test script interactions
- Validate end-to-end workflows
- Test with real QEMU/proot instances

### Manual Testing Checklist
- [ ] Fresh installation works
- [ ] VM starts successfully
- [ ] SSH connection established
- [ ] Docker works inside VM
- [ ] Development tools installed
- [ ] All scripts have correct permissions
- [ ] Error handling works properly

## 📚 Resources

### Documentation
- [README.md](README.md) - Project overview
- [SETUP.md](SETUP.md) - Installation guide
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [ROADMAP.md](ROADMAP.md) - Future plans

### External Resources
- [Bash Reference Manual](https://www.gnu.org/software/bash/manual/)
- [Go Documentation](https://golang.org/doc/)
- [QEMU Documentation](https://www.qemu.org/documentation/)
- [proot Documentation](https://proot-me.github.io/)

### Community
- [GitHub Issues](https://github.com/ghost-chain-unity/proot-avm/issues)
- [GitHub Discussions](https://github.com/ghost-chain-unity/proot-avm/discussions)
- [Discord Channel](https://discord.gg/proot-avm) (future)

---

Happy coding! 🎉</content>
<parameter name="filePath">/workspaces/proot-avm/DEVELOPMENT.md