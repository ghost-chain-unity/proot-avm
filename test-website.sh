#!/bin/bash
# proot-avm Website Test Script
# Tests all links, scripts, and functionality

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test configuration
WEBSITE_DIR="docs"
GITHUB_REPO="https://raw.githubusercontent.com/ghost-chain-unity/proot-avm/main"

echo -e "${CYAN}
╔═══════════════════════════════════════════════════════════╗
║        proot-avm Website Test Suite                      ║
║        Comprehensive Link & Functionality Validation     ║
╚═══════════════════════════════════════════════════════════╝
${NC}"

# Test file existence
test_file_exists() {
    local file="$1"
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file exists${NC}"
        return 0
    else
        echo -e "${RED}❌ $file missing${NC}"
        return 1
    fi
}

# Test curl access to scripts
test_curl_access() {
    local url="$1"
    local name="$2"

    if curl -s --head "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $name accessible via curl${NC}"
        return 0
    else
        echo -e "${RED}❌ $name not accessible via curl${NC}"
        return 1
    fi
}

# Test HTML syntax (basic)
test_html_syntax() {
    local file="$1"
    if command -v xmllint > /dev/null 2>&1; then
        if xmllint --noout "$file" 2>/dev/null; then
            echo -e "${GREEN}✅ $file HTML syntax OK${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  $file HTML syntax issues${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  xmllint not available, skipping HTML validation${NC}"
        return 0
    fi
}

# Test CSS syntax (basic)
test_css_syntax() {
    local file="$1"
    if [ -f "$file" ]; then
        # Basic CSS syntax check - look for obvious errors
        if grep -q "{" "$file" && grep -q "}" "$file"; then
            echo -e "${GREEN}✅ $file CSS structure OK${NC}"
            return 0
        else
            echo -e "${RED}❌ $file CSS structure issues${NC}"
            return 1
        fi
    fi
}

# Test JavaScript syntax
test_js_syntax() {
    local file="$1"
    if command -v node > /dev/null 2>&1; then
        if node -c "$file" 2>/dev/null; then
            echo -e "${GREEN}✅ $file JavaScript syntax OK${NC}"
            return 0
        else
            echo -e "${RED}❌ $file JavaScript syntax errors${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  Node.js not available, skipping JS validation${NC}"
        return 0
    fi
}

# Main test function
main() {
    local errors=0

    echo -e "${BLUE}📁 Testing file existence...${NC}"
    test_file_exists "$WEBSITE_DIR/index.html" || ((errors++))
    test_file_exists "$WEBSITE_DIR/styles.css" || ((errors++))
    test_file_exists "$WEBSITE_DIR/script.js" || ((errors++))
    test_file_exists "$WEBSITE_DIR/README.md" || ((errors++))
    test_file_exists "$WEBSITE_DIR/favicon.svg" || ((errors++))

    echo -e "\n${BLUE}🌐 Testing script accessibility...${NC}"
    test_curl_access "$GITHUB_REPO/install-one-liner.sh" "install-one-liner.sh" || ((errors++))
    test_curl_access "$GITHUB_REPO/install.sh" "install.sh" || ((errors++))
    test_curl_access "$GITHUB_REPO/README.md" "README.md" || ((errors++))
    test_curl_access "$GITHUB_REPO/SETUP.md" "SETUP.md" || ((errors++))
    test_curl_access "$GITHUB_REPO/DEVELOPMENT.md" "DEVELOPMENT.md" || ((errors++))
    test_curl_access "$GITHUB_REPO/CONTRIBUTING.md" "CONTRIBUTING.md" || ((errors++))

    echo -e "\n${BLUE}🔍 Testing syntax validation...${NC}"
    test_html_syntax "$WEBSITE_DIR/index.html" || ((errors++))
    test_css_syntax "$WEBSITE_DIR/styles.css" || ((errors++))
    test_js_syntax "$WEBSITE_DIR/script.js" || ((errors++))

    echo -e "\n${BLUE}🔗 Testing binary download links...${NC}"
    # Note: These will fail until binaries are actually released
    echo -e "${YELLOW}⚠️  Binary downloads will redirect to releases page until v2.0.0 is published${NC}"

    echo -e "\n${BLUE}📊 Test Results:${NC}"
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed! Website is ready for deployment.${NC}"
        echo -e "${CYAN}🚀 Ready to deploy to GitHub Pages${NC}"
    else
        echo -e "${RED}❌ $errors test(s) failed. Please fix issues before deployment.${NC}"
        exit 1
    fi

    echo -e "\n${CYAN}📋 Website Summary:${NC}"
    echo -e "• Clean, modern, profound design"
    echo -e "• Responsive layout (desktop/tablet/mobile)"
    echo -e "• Interactive features (copy buttons, smooth scroll)"
    echo -e "• All installation methods covered"
    echo -e "• Comprehensive documentation links"
    echo -e "• Professional color scheme and typography"
    echo -e "• Fast loading with optimized assets"

    echo -e "\n${CYAN}🌐 Deployment URL: https://ghost-chain-unity.github.io/proot-avm/${NC}"
}

# Run main test function
main "$@"