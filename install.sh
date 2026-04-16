#!/bin/bash
#===============================================================================
# One-line installer for Frappe/ERPNext MCP Setup
# Usage: curl -fsSL https://raw.githubusercontent.com/adharsh242001/frappe-mcp-setup/main/install.sh | bash
#        curl -fsSL https://raw.githubusercontent.com/adharsh242001/frappe-mcp-setup/main/install.sh | bash -s -- --non-interactive ...
#===============================================================================

set -e

INSTALLER_VERSION="1.0.0"
INSTALL_DIR="${HOME}/frappe-mcp-setup"
REPO_URL="${REPO_URL:-https://raw.githubusercontent.com/adharsh242001/frappe-mcp-setup/main}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Parse inline arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --repo)
            REPO_URL="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║   🚀 Frappe/ERPNext MCP Setup Installer                          ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# Check prerequisites
print_info "Checking prerequisites..."

if ! command -v curl &> /dev/null; then
    print_error "curl is required but not installed"
    exit 1
fi

if ! command -v git &> /dev/null; then
    print_error "git is required but not installed"
    exit 1
fi

# Create installation directory
print_info "Installing to: $INSTALL_DIR"

if [ -d "$INSTALL_DIR" ]; then
    print_info "Directory exists, updating..."
    cd "$INSTALL_DIR"
    git pull origin main 2>/dev/null || true
else
    git clone --depth 1 https://github.com/adharsh242001/frappe-mcp-setup.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Make scripts executable
chmod +x setup-frappe-mcp.sh
chmod +x install.sh 2>/dev/null || true

print_success "Installation complete!"
echo ""
echo "Next steps:"
echo ""
echo "  1. Run setup:"
echo "     cd $INSTALL_DIR"
echo "     ./setup-frappe-mcp.sh"
echo ""
echo "  2. Or run with arguments:"
echo "     ./setup-frappe-mcp.sh --non-interactive \\"
echo "       --url 'https://erp.example.com' \\"
echo "       --api-key 'xxx' \\"
echo "       --api-secret 'yyy' \\"
echo "       --preset standard"
echo ""
echo "  3. Or use one-liner with inline args:"
echo "     curl -fsSL $REPO_URL/setup.sh | bash -s -- \\"
echo "       --non-interactive \\"
echo "       --url 'https://erp.example.com' \\"
echo "       --api-key 'xxx' \\"
echo "       --api-secret 'yyy'"
echo ""
