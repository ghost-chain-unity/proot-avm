#!/bin/bash
# proot-avm GitHub Pages Install Redirect
# This script redirects to the actual installer

echo "Redirecting to proot-avm installer..."
curl -fsSL https://raw.githubusercontent.com/ghost-chain-unity/proot-avm/main/scripts/install/install-one-liner.sh | bash