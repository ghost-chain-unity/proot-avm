#!/bin/sh
# Alpine Setup-Alpine Automation Script
# Automates the initial Alpine setup-alpine process

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Generate random password
PASSWORD=$(openssl rand -base64 12 | tr -d "=+/")

# Setup answers file
cat > /tmp/setup-alpine-answers.txt << EOF
# Pre-configured answers for Alpine setup-alpine

# System configuration
KEYMAPOPTS="us us"
HOSTNAMEOPTS="alpine-vm"
TIMEZONEOPTS="UTC"
PROXYOPTS="none"

# User configuration
USEROPTS="none"

# SSH configuration
SSHDOPTS="openssh"

# NTP configuration
NTPDOPTS="chrony"

# Disk configuration
DISKOPTS="sys"

# APK repositories
APKREPOSOPTS="main"

# Root password
ROOTPW="$PASSWORD"
EOF

echo -e "${YELLOW}🔧 Running automated Alpine setup...${NC}"
setup-alpine -f /tmp/setup-alpine-answers.txt

# Set root password explicitly (in case setup-alpine doesn't)
echo "root:$PASSWORD" | chpasswd

echo -e "${GREEN}✅ Alpine setup complete!${NC}"
echo -e "${MAGENTA}Login Info:${NC}"
echo -e "  Hostname: alpine-vm"
echo -e "  Username: root"
echo -e "  Password: $PASSWORD"
echo -e "${YELLOW}⚠️  Save this password securely!${NC}"

# Clean up
rm /tmp/setup-alpine-answers.txt