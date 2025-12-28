#!/usr/bin/env bash
# proot-avm Documentation Website Generator
# Generates a modern documentation site using Hugo

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if Hugo is available
if ! command -v hugo &> /dev/null; then
    echo -e "${YELLOW}⚠️  Hugo not found. Installing...${NC}"

    if command -v pkg &> /dev/null; then
        pkg install -y hugo
    elif command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y hugo
    elif command -v brew &> /dev/null; then
        brew install hugo
    else
        echo -e "${RED}❌ Please install Hugo manually from https://gohugo.io${NC}"
        exit 1
    fi
fi

# Documentation directory
DOCS_DIR="$HOME/.proot-avm-docs"
if [ ! -d "$DOCS_DIR" ]; then
    echo -e "${CYAN}📚 Setting up documentation website...${NC}"
    mkdir -p "$DOCS_DIR"
    cd "$DOCS_DIR"

    # Initialize Hugo site
    hugo new site .

    # Create config.toml
    cat > config.toml << 'EOF'
baseURL = "https://alpinevm.qzz.io"
languageCode = "en-us"
title = "proot-avm Documentation"
theme = "hugo-book"

# Book configuration
[params]
  BookTheme = 'auto'
  BookToC = true
  BookRepo = 'https://github.com/ghost-chain-unity/proot-avm'
  BookCommitPath = 'commit'
  BookEditPath = 'edit/main'
  BookDateFormat = 'January 2, 2006'
  BookSearch = true
  BookComments = false
  BookPortableLinks = true
  BookSection = 'docs'

[menu]
  [[menu.main]]
    name = "Home"
    url = "/"
    weight = 1

  [[menu.main]]
    name = "Getting Started"
    url = "/docs/getting-started/"
    weight = 10

  [[menu.main]]
    name = "User Guide"
    url = "/docs/user-guide/"
    weight = 20

  [[menu.main]]
    name = "Developer Guide"
    url = "/docs/developer/"
    weight = 30

  [[menu.main]]
    name = "API Reference"
    url = "/docs/api/"
    weight = 40

  [[menu.main]]
    name = "Contributing"
    url = "/docs/contributing/"
    weight = 50

[markup]
  [markup.goldmark]
    [markup.goldmark.renderer]
      unsafe = true
  [markup.highlight]
    style = "github"
  [markup.tableOfContents]
    endLevel = 3
    ordered = false
    startLevel = 2

[taxonomies]
  tag = "tags"
  category = "categories"
EOF

    # Install theme
    git clone https://github.com/alex-shpak/hugo-book themes/hugo-book

    # Create content structure
    mkdir -p content/docs/{getting-started,user-guide,developer,api,contributing}

    # Create _index.md
    cat > content/_index.md << 'EOF'
---
title: "proot-avm"
type: docs
---

# 🚀 proot-avm

**Modern Alpine VM Manager for Termux**

proot-avm is a powerful, modern virtual machine management platform designed specifically for mobile development environments. Run full Linux development environments on your Android device with ease.

## ✨ Features

- **🚀 Modern CLI**: Go-based command line interface with AI assistance
- **🌐 Web Dashboard**: Beautiful web interface for VM management
- **🤖 AI Integration**: Intelligent suggestions and automated setup
- **📊 Real-time Monitoring**: Live performance metrics and logs
- **🔧 Multi-VM Support**: Run multiple VMs simultaneously
- **☁️ Cloud Ready**: Integration with cloud services
- **🎨 Modern UI**: Terminal UI and responsive web interfaces

## 🚀 Quick Start

```bash
# Install proot-avm
curl -fsSL https://alpinevm.qzz.io/install.sh | bash

# Start your first VM
avm-go first-boot

# Launch dashboard
avm-go dashboard
```

## 📱 Mobile-First Design

Built specifically for mobile development workflows, proot-avm brings the power of full Linux environments to your Android device without compromising on features or performance.

## 🤝 Community

Join our community of developers building the future of mobile development:

- [GitHub](https://github.com/ghost-chain-unity/proot-avm)
- [Discord](https://discord.gg/proot-avm)
- [Documentation](https://alpinevm.qzz.io/docs)

---

{{< button relref="/docs/getting-started" >}}Get Started{{< /button >}}
EOF

    # Create getting started guide
    cat > content/docs/getting-started/_index.md << 'EOF'
---
title: "Getting Started"
weight: 10
---

# Getting Started with proot-avm

Welcome to proot-avm! This guide will help you get up and running with your first Alpine Linux VM on Android.

## 📋 Prerequisites

- **Android Device**: Running Android 7.0 or later
- **Termux**: Latest version from F-Droid or GitHub
- **Storage**: At least 2GB free space
- **Internet**: Stable connection for downloads

## 🚀 Installation

### One-Line Install

```bash
curl -fsSL https://alpinevm.qzz.io/install.sh | bash
```

### Manual Install

```bash
# Clone repository
git clone https://github.com/ghost-chain-unity/proot-avm.git
cd proot-avm

# Run installer
bash install.sh
```

## 🏁 First Boot Setup

After installation, run the first boot setup:

```bash
avm-go first-boot
```

This will:
- Download Alpine Linux ISO
- Create your VM configuration
- Set up SSH access
- Install essential development tools

## 🌐 Launch Dashboard

Open the web dashboard for visual management:

```bash
avm-go dashboard
```

Visit `http://localhost:3000` in your browser.

## 🔧 Basic Usage

```bash
# Start VM
avm-go start

# Check status
avm-go status

# SSH into VM
avm-go ssh

# Stop VM
avm-go stop
```

## 🎯 Next Steps

- [Configure your development environment](/docs/user-guide/configuration/)
- [Install additional tools](/docs/user-guide/tools/)
- [Learn advanced features](/docs/user-guide/advanced/)
EOF

    # Create user guide
    cat > content/docs/user-guide/_index.md << 'EOF'
---
title: "User Guide"
weight: 20
---

# User Guide

Master the full capabilities of proot-avm for your development workflow.

## 💻 Daily Usage

### Starting and Stopping VMs

```bash
# Start VM in background
avm-go start --headless

# Start with display
avm-go start

# Stop VM
avm-go stop

# Check status
avm-go status --json
```

### SSH Access

```bash
# Connect via SSH
avm-go ssh

# Or manually
ssh -p 2222 root@localhost
```

### Performance Monitoring

```bash
# Real-time monitoring
avm-go monitor --continuous

# View in dashboard
avm-go dashboard
```

## ⚙️ Configuration

### VM Configuration

Edit `~/.avm/config.json`:

```json
{
  "vm_name": "alpine-dev",
  "vm_ram": "2048",
  "vm_cpu": "2",
  "ssh_port": "2222",
  "vm_image": "alpine.img",
  "log_file": "/tmp/avm.log",
  "pid_file": "/tmp/avm-vm.pid"
}
```

### Environment Variables

```bash
# OpenAI API for AI features
export OPENAI_API_KEY="your-api-key"

# Custom dashboard port
export AVM_DASHBOARD_PORT="3001"
```

## 🛠️ Development Tools

### Installing Tools

```bash
# Inside VM
apk add git nodejs npm python3 go rust

# Or use AI assistant
avm-go ai-assist --query "install Node.js development environment"
```

### Popular Stacks

#### Node.js Development
```bash
avm-go ai-assist --query "setup Node.js development environment"
```

#### Python Development
```bash
avm-go ai-assist --query "setup Python data science environment"
```

#### Go Development
```bash
avm-go ai-assist --query "setup Go development environment"
```

## 🌐 Web Dashboard

The web dashboard provides:

- **Real-time monitoring** of VM performance
- **Visual controls** for start/stop operations
- **AI assistance** integrated interface
- **Log viewing** and system diagnostics
- **Responsive design** for mobile and desktop

## 🤖 AI Features

### Getting Help

```bash
# General assistance
avm-go ai-assist

# Specific queries
avm-go ai-assist --query "how to install Docker"
avm-go ai-assist --query "optimize VM performance"
```

### AI-Powered Setup

The AI assistant can help with:
- Development environment setup
- Performance optimization
- Troubleshooting issues
- Best practices recommendations
EOF

    # Create developer guide
    cat > content/docs/developer/_index.md << 'EOF'
---
title: "Developer Guide"
weight: 30
---

# Developer Guide

Contribute to proot-avm and extend its capabilities.

## 🏗️ Architecture

### Core Components

- **Go CLI** (`avm-go/`): Main command-line interface
- **Web Dashboard** (`dashboard-v2.sh`): React-based web interface
- **Bash Scripts** (`scripts/`): Legacy compatibility layer
- **Configuration** (`~/.avm/config.json`): VM settings

### Technology Stack

- **Backend**: Go, Express.js, Socket.io
- **Frontend**: React, Chart.js, Tailwind CSS
- **Infrastructure**: QEMU, proot-distro, Alpine Linux
- **AI**: OpenAI GPT integration

## 🚀 Development Setup

### Prerequisites

```bash
# Go 1.21+
go version

# Node.js 18+
node --version

# Hugo for docs
hugo version
```

### Building from Source

```bash
# Clone repository
git clone https://github.com/ghost-chain-unity/proot-avm.git
cd proot-avm

# Build Go CLI
cd avm-go
go mod tidy
go build -o ../avm-go .

# Build dashboard
cd ../dashboard
npm install
npm run build
```

### Running Tests

```bash
# Go tests
cd avm-go
go test -v ./...

# Dashboard tests
cd ../dashboard
npm test
```

## 🔧 Extending proot-avm

### Adding New Commands

1. Add command to `main.go`
2. Implement handler function
3. Add tests in `main_test.go`
4. Update documentation

Example:

```go
func newCommand(c *cli.Context) error {
    // Implementation
    return nil
}
```

### Web Dashboard Extensions

1. Add API endpoint in `server.js`
2. Create React component
3. Update routing
4. Add tests

### AI Integration

Extend AI capabilities:

```javascript
// Add new AI prompts
const prompts = {
    'docker-setup': 'Help set up Docker environment...',
    'performance': 'Optimize VM performance...'
};
```

## 📊 Performance Optimization

### VM Performance

- Use KVM when available
- Optimize RAM allocation
- Monitor resource usage
- Implement caching strategies

### Code Optimization

- Profile Go applications
- Optimize React rendering
- Minimize bundle sizes
- Implement lazy loading

## 🔒 Security

### Best Practices

- Validate all inputs
- Use secure defaults
- Implement proper authentication
- Regular security audits

### VM Security

- Isolate VM networks
- Use secure SSH keys
- Regular updates
- Firewall configuration

## 📈 Monitoring & Analytics

### Metrics Collection

- VM performance metrics
- User interaction data
- Error tracking
- Feature usage statistics

### Analytics Integration

```go
// Example metrics collection
type Metrics struct {
    Command string
    Duration time.Duration
    Success  bool
    UserID   string
}
```

## 🚀 Deployment

### Release Process

1. Update version numbers
2. Run full test suite
3. Build release binaries
4. Create GitHub release
5. Update documentation
6. Deploy dashboard updates

### CI/CD Pipeline

GitHub Actions handles:
- Automated testing
- Binary builds
- Documentation deployment
- Release creation
EOF

    # Create API reference
    cat > content/docs/api/_index.md << 'EOF'
---
title: "API Reference"
weight: 40
---

# API Reference

Complete API documentation for proot-avm.

## 🌐 REST API

### Base URL
```
http://localhost:3000/api
```

### Endpoints

#### GET /api/status
Get VM status information.

**Response:**
```json
{
  "is_running": true,
  "cpu_usage": 15.7,
  "mem_usage": 512.3,
  "uptime": "2h 34m"
}
```

#### POST /api/start
Start the VM.

**Response:**
```json
{
  "success": true,
  "output": "VM started successfully"
}
```

#### POST /api/stop
Stop the VM.

**Response:**
```json
{
  "success": true,
  "output": "VM stopped successfully"
}
```

#### GET /api/metrics
Get detailed performance metrics.

**Response:**
```json
{
  "cpu": 15.7,
  "memory": 512.3,
  "network": 45.2,
  "disk": 23.1,
  "timestamp": "2025-01-28T10:30:00Z"
}
```

#### POST /api/ai-assist
Get AI assistance.

**Request:**
```json
{
  "query": "How to install Node.js?"
}
```

**Response:**
```json
{
  "suggestions": [
    "Use apk add nodejs npm",
    "Consider using nvm for version management"
  ],
  "commands": [
    "apk add nodejs npm",
    "npm install -g nvm"
  ],
  "warnings": []
}
```

#### GET /api/logs
Get system logs.

**Response:**
```json
{
  "logs": [
    "2025-01-28 10:30:00 VM started",
    "2025-01-28 10:30:05 SSH service started",
    "2025-01-28 10:31:00 AI query processed"
  ]
}
```

## 🔌 WebSocket API

### Connection
```javascript
const socket = io('http://localhost:3000');
```

### Events

#### status
Real-time VM status updates.

```javascript
socket.on('status', (data) => {
  console.log('Status:', data.status);
  console.log('Metrics:', data.metrics);
});
```

#### command-result
Command execution results.

```javascript
socket.on('command-result', (result) => {
  console.log('Command output:', result.result);
});
```

#### error
Error notifications.

```javascript
socket.on('error', (error) => {
  console.error('Error:', error.message);
});
```

## 📋 CLI API

### Command Structure

```bash
avm-go [command] [flags]
```

### Available Commands

- `start` - Start VM
- `stop` - Stop VM
- `status` - Check status
- `ssh` - SSH access
- `dashboard` - Launch dashboard
- `first-boot` - Initial setup
- `ai-assist` - AI help
- `monitor` - Performance monitoring
- `tui` - Terminal UI
- `backup` - Create backup
- `restore` - Restore from backup
- `config` - Configuration management

### Flags

- `--headless` - Start VM without display
- `--config` - Specify config file
- `--json` - JSON output
- `--continuous` - Continuous monitoring
- `--query` - AI query

## 📊 Data Models

### VMStatus
```go
type VMStatus struct {
    IsRunning bool    `json:"is_running"`
    CPUUsage  float64 `json:"cpu_usage"`
    MemUsage  float64 `json:"mem_usage"`
    Uptime    string  `json:"uptime"`
}
```

### AIResponse
```go
type AIResponse struct {
    Suggestions []string `json:"suggestions"`
    Commands    []string `json:"commands"`
    Warnings    []string `json:"warnings"`
}
```

### Config
```go
type Config struct {
    VMName    string `json:"vm_name" validate:"required"`
    VMRAM     string `json:"vm_ram" validate:"required"`
    VMCPU     string `json:"vm_cpu" validate:"required"`
    SSHPort   string `json:"ssh_port" validate:"required"`
    VMImage   string `json:"vm_image" validate:"required"`
    LogFile   string `json:"log_file"`
    PIDFile   string `json:"pid_file"`
}
```

## ⚠️ Error Codes

- `400` - Bad Request
- `401` - Unauthorized
- `404` - Not Found
- `500` - Internal Server Error

## 🔐 Authentication

API endpoints are currently open. Authentication will be added in future versions for enterprise deployments.

## 📈 Rate Limits

- REST API: 100 requests per minute
- WebSocket: Unlimited (local only)
- AI API: 50 requests per hour (when using OpenAI)
EOF

    # Create contributing guide
    cat > content/docs/contributing/_index.md << 'EOF'
---
title: "Contributing"
weight: 50
---

# Contributing to proot-avm

We welcome contributions from the community! Here's how you can help make proot-avm better.

## 🐛 Reporting Issues

### Bug Reports

When reporting bugs, please include:

1. **Version information**
   ```bash
   avm-go --version
   uname -a
   ```

2. **Steps to reproduce**
   - Clear, numbered steps
   - Expected vs actual behavior

3. **Logs and error messages**
   ```bash
   avm-go status --json
   cat /tmp/avm.log
   ```

4. **Environment details**
   - Android version
   - Termux version
   - Available RAM/storage

### Feature Requests

For new features, please:

- Check if the feature already exists
- Describe the use case clearly
- Explain why it's needed
- Suggest implementation approach

## 💻 Development Workflow

### 1. Fork and Clone

```bash
git clone https://github.com/your-username/proot-avm.git
cd proot-avm
git checkout -b feature/your-feature-name
```

### 2. Development Setup

```bash
# Install dependencies
cd avm-go
go mod tidy

cd ../dashboard
npm install

# Run tests
go test ./...
npm test
```

### 3. Code Standards

#### Go Code
- Follow standard Go formatting (`go fmt`)
- Use `gofmt` and `golint`
- Write comprehensive tests
- Add documentation comments

#### JavaScript/React
- Use ESLint and Prettier
- Follow React best practices
- Write unit tests with Jest
- Use TypeScript for new components

#### Bash Scripts
- Use `shellcheck` for linting
- Follow POSIX standards
- Add error handling
- Include usage documentation

### 4. Commit Guidelines

```bash
# Format: type(scope): description

feat(cli): add new backup command
fix(dashboard): resolve memory leak in metrics
docs(api): update endpoint documentation
test(monitor): add performance test cases
```

### 5. Pull Request Process

1. **Update documentation** for any new features
2. **Add tests** for new functionality
3. **Update CHANGELOG.md** with your changes
4. **Ensure CI passes** all checks
5. **Request review** from maintainers

## 🎯 Areas for Contribution

### High Priority

- **Performance Optimization**
  - VM startup time improvements
  - Memory usage optimization
  - Network performance enhancements

- **Mobile UX**
  - Better touch interfaces
  - Gesture controls
  - Voice commands

- **AI Features**
  - More intelligent suggestions
  - Automated troubleshooting
  - Predictive maintenance

### Medium Priority

- **Multi-VM Support**
  - Run multiple VMs simultaneously
  - VM templates and snapshots
  - Resource sharing

- **Cloud Integration**
  - AWS/GCP deployment
  - Backup to cloud storage
  - Remote access

- **Package Management**
  - More language support
  - Dependency management
  - Version pinning

### Future Enhancements

- **Enterprise Features**
  - RBAC and permissions
  - Audit logging
  - SSO integration

- **Advanced Networking**
  - VPN integration
  - Port forwarding
  - Network isolation

- **Developer Tools**
  - IDE integrations
  - CI/CD pipelines
  - Monitoring dashboards

## 🧪 Testing

### Running Tests

```bash
# Go tests
cd avm-go
go test -v -race -cover ./...

# JavaScript tests
cd ../dashboard
npm test -- --coverage

# Integration tests
bash scripts/test-integration.sh
```

### Writing Tests

#### Go Tests
```go
func TestVMStart(t *testing.T) {
    // Test VM starting logic
    config := Config{VMRAM: "1024", VMCPU: "1"}
    err := startVM(config)
    assert.NoError(t, err)
    assert.True(t, isRunning())
}
```

#### React Tests
```javascript
import { render, screen } from '@testing-library/react';
import VMControls from './VMControls';

test('renders start button', () => {
  render(<VMControls />);
  const startButton = screen.getByText(/start vm/i);
  expect(startButton).toBeInTheDocument();
});
```

## 📚 Documentation

### Updating Docs

1. Edit files in `content/docs/`
2. Use Hugo for local preview:
   ```bash
   cd docs
   hugo server -D
   ```
3. Check links and formatting
4. Update API documentation for code changes

### Documentation Standards

- Use clear, concise language
- Include code examples
- Provide troubleshooting sections
- Keep screenshots updated

## 🎉 Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Featured in community showcases
- Eligible for contributor swag

## 📞 Getting Help

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and ideas
- **Discord**: For real-time chat and support
- **Documentation**: For self-service help

## 📋 Code of Conduct

Please follow our code of conduct:
- Be respectful and inclusive
- Focus on constructive feedback
- Help newcomers learn
- Maintain professional standards

---

Thank you for contributing to proot-avm! 🚀
EOF

    echo -e "${GREEN}✅ Documentation website setup complete!${NC}"
fi

# Build and serve the documentation
cd "$DOCS_DIR"
echo -e "${BLUE}📚 Building documentation website...${NC}"
hugo --minify

echo -e "${CYAN}🚀 Serving documentation at http://localhost:1313${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
hugo server --bind 0.0.0.0 --baseURL http://localhost:1313