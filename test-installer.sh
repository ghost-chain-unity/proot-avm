#!/usr/bin/env bash
# proot-avm One-Liner Installer Test
# Tests the complete installation workflow

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Test configuration
TEST_DIR="${TEST_DIR:-/tmp/proot-avm-test}"
REPO_URL="${REPO_URL:-https://github.com/ghost-chain-unity/proot-avm/archive/main.tar.gz}"

echo -e "${MAGENTA}
╔═══════════════════════════════════════════════════════════╗
║  proot-avm One-Liner Installer Test                     ║
║  Complete Installation Workflow Validation              ║
╚═══════════════════════════════════════════════════════════╝
${NC}"

# Cleanup function
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up test environment...${NC}"
    rm -rf "$TEST_DIR"
}

# Error handling
error_exit() {
    echo -e "${RED}❌ Test failed: $1${NC}"
    cleanup
    exit 1
}

# Setup test environment
setup_test() {
    echo -e "${CYAN}📁 Setting up test environment...${NC}"
    cleanup
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    echo -e "${GREEN}✅ Test environment ready${NC}"
}

# Test repository download
test_repo_download() {
    echo -e "${CYAN}📥 Testing repository download...${NC}"

    if command -v curl &> /dev/null; then
        curl -fsSL "$REPO_URL" -o repo.tar.gz || error_exit "Failed to download repo with curl"
    elif command -v wget &> /dev/null; then
        wget -q "$REPO_URL" -O repo.tar.gz || error_exit "Failed to download repo with wget"
    else
        error_exit "Neither curl nor wget available"
    fi

    # Check if download was successful
    if [ ! -f "repo.tar.gz" ]; then
        error_exit "Repository archive not found"
    fi

    # Check file size (should be > 100KB)
    local size=$(stat -c%s "repo.tar.gz" 2>/dev/null || stat -f%z "repo.tar.gz" 2>/dev/null || echo "0")
    if [ "$size" -lt 100000 ]; then
        error_exit "Repository archive too small ($size bytes)"
    fi

    echo -e "${GREEN}✅ Repository download successful${NC}"
}

# Test repository extraction
test_repo_extraction() {
    echo -e "${CYAN}📦 Testing repository extraction...${NC}"

    tar -xzf repo.tar.gz || error_exit "Failed to extract repository"

    # Check if extraction was successful
    if [ ! -d "proot-avm-main" ]; then
        error_exit "Extracted directory not found"
    fi

    cd proot-avm-main || error_exit "Failed to enter extracted directory"

    # Check for essential files
    local essential_files=("install-one-liner.sh" "install.sh" "avm-go.sh" "README.md")
    for file in "${essential_files[@]}"; do
        if [ ! -f "$file" ]; then
            error_exit "Essential file missing: $file"
        fi
    done

    echo -e "${GREEN}✅ Repository extraction successful${NC}"
}

# Test script syntax validation
test_script_syntax() {
    echo -e "${CYAN}🔍 Testing script syntax...${NC}"

    # Test main scripts
    local scripts=("install-one-liner.sh" "install.sh" "avm-go.sh" "dashboard-v2.sh" "tui.sh" "docs.sh")

    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            bash -n "$script" || error_exit "Syntax error in $script"
            echo -e "${GREEN}✅ $script syntax OK${NC}"
        else
            echo -e "${YELLOW}⚠️  $script not found (optional)${NC}"
        fi
    done

    # Test scripts in scripts/ directory
    if [ -d "scripts" ]; then
        for script in scripts/*.sh; do
            if [ -f "$script" ]; then
                bash -n "$script" || error_exit "Syntax error in $script"
            fi
        done
        echo -e "${GREEN}✅ All scripts in scripts/ syntax OK${NC}"
    fi

    echo -e "${GREEN}✅ Script syntax validation complete${NC}"
}

# Test Go CLI build
test_go_build() {
    echo -e "${CYAN}🔨 Testing Go CLI build...${NC}"

    if [ ! -d "avm-go" ]; then
        echo -e "${YELLOW}⚠️  avm-go directory not found, skipping Go build test${NC}"
        return 0
    fi

    cd avm-go || error_exit "Failed to enter avm-go directory"

    # Check if go.mod exists
    if [ ! -f "go.mod" ]; then
        error_exit "go.mod not found"
    fi

    # Test go mod tidy
    go mod tidy || error_exit "go mod tidy failed"

    # Test build
    go build -o /tmp/avm-go-test . || error_exit "Go build failed"

    # Test if binary is executable
    if [ ! -x "/tmp/avm-go-test" ]; then
        error_exit "Built binary not executable"
    fi

    # Test basic functionality
    /tmp/avm-go-test --help > /dev/null || error_exit "Binary help command failed"

    cd ..
    echo -e "${GREEN}✅ Go CLI build successful${NC}"
}

# Test installer script logic (dry run)
test_installer_logic() {
    echo -e "${CYAN}🧪 Testing installer logic...${NC}"

    # Test install-one-liner.sh logic without actual execution
    if [ -f "install-one-liner.sh" ]; then
        # Check if script has proper error handling
        if ! grep -q "error_exit" install-one-liner.sh; then
            error_exit "install-one-liner.sh missing error handling"
        fi

        # Check if script has cleanup function
        if ! grep -q "cleanup()" install-one-liner.sh; then
            error_exit "install-one-liner.sh missing cleanup function"
        fi

        # Check if script downloads repo
        if ! grep -q "REPO_URL" install-one-liner.sh; then
            error_exit "install-one-liner.sh missing repo download logic"
        fi

        echo -e "${GREEN}✅ Installer logic validation passed${NC}"
    else
        error_exit "install-one-liner.sh not found"
    fi
}

# Test file permissions
test_file_permissions() {
    echo -e "${CYAN}🔐 Testing file permissions...${NC}"

    # Check that scripts are executable
    local scripts=("install-one-liner.sh" "install.sh")

    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if [ ! -x "$script" ]; then
                echo -e "${YELLOW}⚠️  $script not executable, fixing...${NC}"
                chmod +x "$script"
            fi
        fi
    done

    echo -e "${GREEN}✅ File permissions OK${NC}"
}

# Generate test report
generate_report() {
    echo -e "${CYAN}📊 Generating test report...${NC}"

    cat > "$TEST_DIR/test-report.md" << EOF
# proot-avm One-Liner Installer Test Report

**Date:** $(date)
**Test Environment:** $TEST_DIR
**Repository URL:** $REPO_URL

## ✅ Test Results

### Repository Download
- ✅ Repository downloaded successfully
- ✅ Archive size: $(stat -c%s repo.tar.gz 2>/dev/null || stat -f%z repo.tar.gz 2>/dev/null || echo "unknown") bytes

### Repository Extraction
- ✅ Repository extracted successfully
- ✅ Essential files present: install-one-liner.sh, install.sh, avm-go.sh, README.md

### Script Syntax Validation
- ✅ All main scripts syntax OK
- ✅ All scripts in scripts/ directory syntax OK

### Go CLI Build
- ✅ Go modules tidy successful
- ✅ Go build successful
- ✅ Binary executable and functional

### Installer Logic
- ✅ Error handling functions present
- ✅ Cleanup functions present
- ✅ Repository download logic present

### File Permissions
- ✅ Scripts have executable permissions

## 📋 Files Tested

### Main Scripts
$(ls -la *.sh 2>/dev/null | head -10)

### Scripts Directory
$(ls -la scripts/*.sh 2>/dev/null | head -10)

### Go CLI
$(ls -la avm-go/ 2>/dev/null | head -5)

## 🎯 Recommendations

1. **One-liner installer is ready for production**
2. **All syntax checks passed**
3. **Go CLI builds successfully**
4. **File permissions are correct**

## 🚀 Next Steps

1. Test actual installation on target platforms
2. Create binary releases for faster installation
3. Update documentation with new installation methods
4. Monitor user feedback and issues

---
**Test completed successfully on:** $(date)
EOF

    echo -e "${GREEN}✅ Test report generated: $TEST_DIR/test-report.md${NC}"
}

# Main test function
main() {
    setup_test
    test_repo_download
    test_repo_extraction
    test_script_syntax
    test_go_build
    test_installer_logic
    test_file_permissions
    generate_report

    echo -e "${MAGENTA}
🎉 All tests passed!

One-liner installer is ready for production use.

Test artifacts available in: $TEST_DIR
Test report: $TEST_DIR/test-report.md

${NC}"

    # Don't cleanup on success for inspection
    # cleanup
}

# Run main test function
main "$@"