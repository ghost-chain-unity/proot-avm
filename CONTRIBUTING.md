# Contributing to proot-avm

We welcome contributions from everyone! This document outlines the process for contributing to the proot-avm project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Process](#development-process)
- [Submitting Changes](#submitting-changes)
- [Reporting Issues](#reporting-issues)
- [Community Guidelines](#community-guidelines)

## 🤝 Code of Conduct

This project follows a code of conduct to ensure a welcoming environment for all contributors. By participating, you agree to:

- **Be respectful** - Treat everyone with respect and kindness
- **Be inclusive** - Welcome people from all backgrounds and experiences
- **Be collaborative** - Work together to improve the project
- **Be patient** - Understand that everyone has different skill levels and time constraints
- **Be constructive** - Focus on solutions rather than problems

## 🚀 Getting Started

### Prerequisites

Before contributing, make sure you have:

- Git (2.0+)
- Bash (4.0+)
- Go (1.21+) for CLI development
- Basic understanding of shell scripting and virtualization

### Setup Development Environment

```bash
# Fork and clone the repository
git clone https://github.com/YOUR_USERNAME/proot-avm.git
cd proot-avm

# Add upstream remote
git remote add upstream https://github.com/ghost-chain-unity/proot-avm.git

# Install development dependencies
./install.sh --dev

# Run tests to ensure everything works
./test-installer.sh
```

## 💡 How to Contribute

### Types of Contributions

We welcome various types of contributions:

- **🐛 Bug fixes** - Fix issues and improve stability
- **✨ New features** - Add new functionality
- **🤖 AI Integration** - Improve AI assistant, add new providers, enhance AI responses
- **📚 Documentation** - Improve docs, guides, and examples
- **🧪 Tests** - Add or improve test coverage
- **🔧 Tools** - Development tools and scripts
- **🎨 UI/UX** - Improve user interface and experience
- **🌐 Translations** - Add support for new languages

### Finding Issues to Work On

- Check [GitHub Issues](https://github.com/ghost-chain-unity/proot-avm/issues) for open tasks
- Look for issues labeled `good first issue` or `help wanted`
- Check the [ROADMAP.md](ROADMAP.md) for planned features
- Join discussions in [GitHub Discussions](https://github.com/ghost-chain-unity/proot-avm/discussions)

## 🔄 Development Process

### 1. Choose an Issue

- Comment on the issue to indicate you're working on it
- Wait for maintainer approval if it's a significant change
- Create a new issue if you found a bug or want to suggest a feature

### 2. Create a Branch

```bash
# Create and switch to a new branch
git checkout -b feature/your-feature-name
# or
git checkout -b bugfix/issue-number-description

# Example branches:
git checkout -b feature/add-vm-snapshots
git checkout -b bugfix/ssh-connection-timeout
git checkout -b docs/update-installation-guide
```

### 3. Make Changes

Follow our coding standards and guidelines:

#### Bash Scripts
- Use POSIX-compliant syntax
- Include error handling with `set -e`
- Add comments for complex logic
- Test with `bash -n script.sh`

#### Go Code
- Follow standard Go conventions
- Use `go fmt` for formatting
- Include unit tests
- Add documentation comments

#### Commit Messages
```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance

Examples:
```
feat(vm): add snapshot creation functionality

fix(ssh): resolve connection timeout on slow networks

docs(readme): update installation instructions for v2.0

test(installer): add tests for one-liner installation
```

### 4. Test Your Changes

```bash
# Run the full test suite
./test-installer.sh

# Test specific functionality
avm start console  # Test VM startup
avm ssh           # Test SSH connection
avm exec "docker ps"  # Test command execution

# Check code quality
shellcheck scripts/*.sh  # Bash linting
go vet ./avm-go/         # Go static analysis
go test ./avm-go/        # Run Go tests
```

### 5. Update Documentation

If your changes affect user-facing functionality:

- Update relevant documentation files
- Add examples if introducing new features
- Update CHANGELOG.md if applicable

## 📤 Submitting Changes

### Pull Request Process

1. **Ensure your branch is up to date**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Push your changes**
   ```bash
   git push origin your-branch-name
   ```

3. **Create a Pull Request**
   - Go to your fork on GitHub
   - Click "New Pull Request"
   - Fill out the PR template
   - Reference any related issues

### PR Requirements

Your PR should:
- ✅ Pass all tests
- ✅ Include appropriate tests for new functionality
- ✅ Follow coding standards
- ✅ Include documentation updates
- ✅ Have a clear description of changes
- ✅ Reference related issues

### PR Template

```
## Description
Brief description of the changes made.

## Type of Change
- [ ] Bug fix (non-breaking change)
- [ ] New feature (non-breaking change)
- [ ] Breaking change
- [ ] Documentation update
- [ ] Refactoring

## Testing
- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Manual testing completed

## Screenshots (if applicable)
Add screenshots of UI changes or terminal output.

## Related Issues
Fixes #123, Addresses #456

## Checklist
- [ ] Code follows project style guidelines
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] No breaking changes
```

## 🐛 Reporting Issues

### Bug Reports

When reporting bugs, please include:

- **Clear title** describing the issue
- **Steps to reproduce** the problem
- **Expected behavior** vs actual behavior
- **Environment details**:
  - OS and version
  - Terminal/shell version
  - proot-avm version
  - Hardware specifications
- **Logs and error messages**
- **Screenshots** if applicable

### Feature Requests

For feature requests, please:

- **Check existing issues** to avoid duplicates
- **Describe the problem** you're trying to solve
- **Explain your proposed solution**
- **Consider alternative approaches**
- **Discuss potential impact** on existing functionality

## 🌟 Community Guidelines

### Communication

- Use English for all communications
- Be clear and concise
- Provide context when asking questions
- Share your thought process for complex issues

### Getting Help

- **Documentation**: Check [README.md](README.md), [SETUP.md](SETUP.md), and [DEVELOPMENT.md](DEVELOPMENT.md)
- **Issues**: Search existing issues before creating new ones
- **Discussions**: Use GitHub Discussions for questions and general discussion
- **Discord**: Join our community Discord (link coming soon)

### Recognition

Contributors are recognized through:
- GitHub contributor statistics
- Mention in release notes
- Special contributor badges (future)
- Invitation to become a maintainer (for significant contributions)

## 🎯 Contribution Workflow Summary

1. **Find or create an issue**
2. **Fork the repository**
3. **Create a feature branch**
4. **Make your changes**
5. **Test thoroughly**
6. **Update documentation**
7. **Submit a pull request**
8. **Participate in code review**
9. **Celebrate your contribution! 🎉**

## 📞 Contact

- **Issues**: [GitHub Issues](https://github.com/ghost-chain-unity/proot-avm/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ghost-chain-unity/proot-avm/discussions)
- **Email**: ghost-chain-unity@github.com

Thank you for contributing to proot-avm! Your help makes this project better for everyone. 🚀</content>
<parameter name="filePath">/workspaces/proot-avm/CONTRIBUTING.md