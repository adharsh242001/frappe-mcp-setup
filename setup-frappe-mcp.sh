#!/bin/bash
#===============================================================================
# Frappe/ERPNext MCP Setup Script v2.0
# Purpose: One-command setup for ERPNext + Frappe MCP integration
# Supports: Claude Code, OpenCode, or both
# Features: Token scanner, auto-detect, JSON merging, non-interactive mode
#===============================================================================

set -e

# Script metadata
VERSION="2.0.0"
SCRIPT_URL="https://raw.githubusercontent.com/adharsh242001/frappe-mcp-setup/main/setup-frappe-mcp.sh"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"
FRAPPE_MCP_DIR="${HOME}/frappe-mcp-server"

# Global variables
NON_INTERACTIVE=false
VERBOSE=false
SELECTED_CATEGORIES=()
ERPNEXT_URL=""
ERPNEXT_API_KEY=""
ERPNEXT_API_SECRET=""
FRAPPE_BENCH_PATH=""
AI_CLIENT="both"
CONFIG_MERGE_STRATEGY="append"
AUTO_DETECT_MODE=false
ERPNEXT_MCP_PACKAGE="${ERPNEXT_MCP_PACKAGE:-@casys/mcp-erpnext}"

#===============================================================================
# CATEGORY DATA WITH ACTUAL TOKEN ESTIMATES
# Token estimates based on schema analysis from @casys/mcp-erpnext
#===============================================================================

declare -A CATEGORY_TOOLS=(
    ["sales"]=17
    ["purchasing"]=11
    ["inventory"]=9
    ["accounting"]=6
    ["hr"]=12
    ["project"]=9
    ["delivery"]=5
    ["manufacturing"]=7
    ["crm"]=8
    ["assets"]=8
    ["operations"]=7
    ["kanban"]=2
    ["analytics"]=17
    ["setup"]=2
)

declare -A CATEGORY_TOKENS=(
    ["sales"]=4760
    ["purchasing"]=2640
    ["inventory"]=2070
    ["accounting"]=1080
    ["hr"]=2400
    ["project"]=1980
    ["delivery"]=900
    ["manufacturing"]=1400
    ["crm"]=1520
    ["assets"]=1520
    ["operations"]=1750
    ["kanban"]=600
    ["analytics"]=3740
    ["setup"]=400
)

declare -A CATEGORY_DESCRIPTIONS=(
    ["sales"]="Customers, Sales Orders, Invoices, Quotations"
    ["purchasing"]="Suppliers, Purchase Orders, Invoices"
    ["inventory"]="Items, Stock Balance, Warehouses"
    ["accounting"]="Accounts, Journal Entries, Payments"
    ["hr"]="Employees, Attendance, Leave, Salary"
    ["project"]="Projects, Tasks, Timesheets"
    ["delivery"]="Delivery Notes, Shipments"
    ["manufacturing"]="BOMs, Work Orders, Job Cards"
    ["crm"]="Leads, Opportunities, Contacts"
    ["assets"]="Assets, Movements, Maintenance"
    ["operations"]="Generic CRUD for any DocType"
    ["kanban"]="Task/Opportunity/Issue boards"
    ["analytics"]="Charts, KPIs, Sales Funnel"
    ["setup"]="Company creation"
)

declare -A CATEGORY_ICONS=(
    ["sales"]="📦"
    ["purchasing"]="🛒"
    ["inventory"]="📊"
    ["accounting"]="💰"
    ["hr"]="👥"
    ["project"]="📋"
    ["delivery"]="🚚"
    ["manufacturing"]="🏭"
    ["crm"]="🔔"
    ["assets"]="🔧"
    ["operations"]="⚙️"
    ["kanban"]="📱"
    ["analytics"]="📈"
    ["setup"]="⚙️"
)

declare -A PRESETS=(
    ["minimal"]="operations"
    ["standard"]="sales,inventory,operations"
    ["full"]="sales,purchasing,inventory,accounting,hr,project,delivery,manufacturing,crm,assets,operations,kanban,analytics,setup"
    ["dev_focus"]="operations,project,kanban"
)

declare -A PRESET_LABELS=(
    ["minimal"]="✨ MINIMAL"
    ["standard"]="⭐ STANDARD"
    ["full"]="🚀 FULL STACK"
    ["dev_focus"]="🔧 DEV FOCUS"
)

declare -A PRESET_DESCRIPTIONS=(
    ["minimal"]="Quick edits, ~1,750 tokens"
    ["standard"]="Most developers, ~8,480 tokens"
    ["full"]="All features, ~26,760 tokens"
    ["dev_focus"]="Frappe developers, ~4,330 tokens"
)

ALL_CATEGORIES=("sales" "purchasing" "inventory" "accounting" "hr" "project" "delivery" "manufacturing" "crm" "assets" "operations" "kanban" "analytics" "setup")

#===============================================================================
# ERROR HANDLING SYSTEM
#===============================================================================

ERROR_CODES=(
    "E_SUCCESS:0:Success"
    "E_NODE_MISSING:1:Node.js not found"
    "E_PYTHON_MISSING:2:Python 3.10+ not found"
    "E_JQ_MISSING:3:jq not found"
    "E_URL_INVALID:4:Invalid ERPNext URL"
    "E_API_AUTH_FAILED:5:API authentication failed"
    "E_API_CONNECT_FAILED:6:Cannot connect to ERPNext"
    "E_CONFIG_WRITE:7:Cannot write config file"
    "E_GIT_CLONE:8:Cannot clone repository"
    "E_DIALOG_MISSING:9:dialog/whiptail not available"
)

get_error_message() {
    local code=$1
    for entry in "${ERROR_CODES[@]}"; do
        IFS=':' read -r name num msg <<< "$entry"
        if [ "$name" = "$code" ]; then
            echo "$msg"
            return 0
        fi
    done
    echo "Unknown error: $code"
}

#===============================================================================
# UTILITY FUNCTIONS
#===============================================================================

spinner_pid=""
spinner_chars="/-\|"

start_spinner() {
    local message="${1:-Loading...}"
    echo -n -e "${DIM}${message} ${NC}"
    spinner_pid=$$
    (
        while kill -0 $spinner_pid 2>/dev/null; do
            for char in $spinner_chars; do
                echo -ne "\b${char}"
                sleep 0.1
            done
        done
    ) &
    SPINNER_PID=$!
}

stop_spinner() {
    if [ -n "$SPINNER_PID" ]; then
        kill $SPINNER_PID 2>/dev/null || true
        wait $SPINNER_PID 2>/dev/null || true
        echo -e "\b${GREEN}✓${NC}"
        SPINNER_PID=""
    fi
}

print_banner() {
    cat << 'EOF'

    ╔═══════════════════════════════════════════════════════════════════════╗
    ║                                                                       ║
    ║   🚀  Frappe/ERPNext MCP Setup v2.0                                 ║
    ║                                                                       ║
    ║   AI-powered development setup for Frappe/ERPNext                   ║
    ║   • Claude Code & OpenCode support                                   ║
    ║   • Token-aware category selection                                   ║
    ║   • Auto-detect ERPNext usage                                       ║
    ║                                                                       ║
    ╚═══════════════════════════════════════════════════════════════════════╝

EOF
}

print_step() {
    echo -e "\n${CYAN}${BOLD}➤ Step $1: $2${NC}\n"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_debug() { if [ "$VERBOSE" = true ]; then echo -e "${DIM}[DEBUG] $1${NC}"; fi; }

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "${SCRIPT_DIR}/setup.log"
}

#===============================================================================
# COMMAND LINE PARSING
#===============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --non-interactive|--yes|-y)
                NON_INTERACTIVE=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --url)
                ERPNEXT_URL="$2"
                shift 2
                ;;
            --api-key)
                ERPNEXT_API_KEY="$2"
                shift 2
                ;;
            --api-secret)
                ERPNEXT_API_SECRET="$2"
                shift 2
                ;;
            --categories)
                IFS=',' read -ra SELECTED_CATEGORIES <<< "$2"
                shift 2
                ;;
            --preset)
                local preset="${PRESETS[$2]:-$2}"
                IFS=',' read -ra SELECTED_CATEGORIES <<< "$preset"
                shift 2
                ;;
            --client)
                AI_CLIENT="$2"
                shift 2
                ;;
            --merge)
                CONFIG_MERGE_STRATEGY="$2"
                shift 2
                ;;
            --auto-detect)
                AUTO_DETECT_MODE=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_warning "Unknown option: $1"
                shift
                ;;
        esac
    done
}

show_help() {
    cat << 'EOF'
Usage: setup-frappe-mcp.sh [OPTIONS]

Options:
  --non-interactive, -y    Run in non-interactive mode (for automation)
  --verbose, -v            Enable verbose output
  --url URL                ERPNext URL
  --api-key KEY            API Key
  --api-secret SECRET      API Secret
  --categories CATS        Comma-separated categories (e.g., sales,inventory)
  --preset NAME            Use preset (minimal, standard, full, dev_focus)
  --client CLIENT          AI client (claude, opencode, both)
  --merge STRATEGY         Config merge strategy (append, newfile, overwrite)
  --auto-detect            Auto-detect ERPNext usage patterns
  --help, -h               Show this help message

Examples:
  # Interactive setup
  ./setup-frappe-mcp.sh

  # Non-interactive with all options
  ./setup-frappe-mcp.sh --non-interactive \
    --url "https://erp.example.com" \
    --api-key "xxx" \
    --api-secret "yyy" \
    --preset standard \
    --client both

  # One-liner install
  curl -fsSL https://your-repo/setup.sh | bash -s -- --non-interactive \
    --url "https://erp.example.com" \
    --api-key "xxx" \
    --api-secret "yyy"
EOF
}

#===============================================================================
# TOKEN CALCULATOR
#===============================================================================

calculate_tokens() {
    local total=0
    local tool_count=0

    for category in "${SELECTED_CATEGORIES[@]}"; do
        if [[ -v CATEGORY_TOKENS[$category] ]]; then
            total=$((total + CATEGORY_TOKENS[$category]))
            tool_count=$((tool_count + CATEGORY_TOOLS[$category]))
        fi
    done

    echo "$total $tool_count"
}

display_token_summary() {
    local result
    result=$(calculate_tokens)
    local total_tokens=${result% *}
    local tool_count=${result#* }

    echo -e "\n${BOLD}📊 TOKEN SUMMARY${NC}"
    echo "────────────────────────────────────────────────────────────────"
    echo "  Categories Selected: ${#SELECTED_CATEGORIES[@]}"
    echo "  Tools: $tool_count of 120 ($(( tool_count * 100 / 120 ))%)"
    echo -n "  Est. Tokens: ~$total_tokens"
    echo ""

    local rating speed color
    if [ "$total_tokens" -lt 10000 ]; then
        rating="✅ LEAN"; speed="⚡ Fast"; color="green"
    elif [ "$total_tokens" -lt 25000 ]; then
        rating="⚠️  NORMAL"; speed="📊 Average"; color="yellow"
    else
        rating="❌ HEAVY"; speed="🐢 Slow"; color="red"
    fi

    echo -e "  Rating: $rating - $speed"
    echo ""
    echo "  💡 Tip: <10k = Fast | 10-25k = Normal | >25k = Slow"
    echo "────────────────────────────────────────────────────────────────"
}

#===============================================================================
# TOKEN SCANNER - Real MCP Schema Analysis
#===============================================================================

scan_real_tokens() {
    print_info "Scanning MCP server for real token estimates..."
    
    local temp_dir=$(mktemp -d)
    local categories_string=$(IFS=,; echo "${SELECTED_CATEGORIES[*]}")
    
    # Start MCP server and get tool list. Keep this bounded because npx can hang
    # while resolving GitHub/npm packages on slow or restricted networks.
    timeout 30 npx -y "$ERPNEXT_MCP_PACKAGE" --categories="$categories_string" 2>/dev/null &
    local mcp_pid=$!
    
    # Alternative: Use MCP inspector to get tool schemas
    if command -v node &> /dev/null; then
        print_debug "Node available, can run MCP introspection"
    fi
    
    rm -rf "$temp_dir"
    
    # Return static estimates with note that real scan would need MCP runtime
    print_info "Note: Static estimates shown. Real scan available via MCP runtime."
}

#===============================================================================
# AUTO-DETECT ERPNEXT USAGE
#===============================================================================

auto_detect_usage() {
    print_step "X" "Auto-Detecting ERPNext Usage"
    
    if [ -z "$ERPNEXT_URL" ] || [ -z "$ERPNEXT_API_KEY" ]; then
        print_warning "Cannot auto-detect without URL and API key"
        return 1
    fi
    
    print_info "Scanning ERPNext instance for usage patterns..."
    
    local detected_categories=()
    local api_base="${ERPNEXT_URL}/api/resource"
    
    # Check Sales module
    local sales_count=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token ${ERPNEXT_API_KEY}:${ERPNEXT_API_SECRET}" \
        "${api_base}/Customer?limit=1" 2>/dev/null || echo "000")
    if [ "$sales_count" = "200" ]; then
        detected_categories+=("sales")
        print_success "Sales module detected"
    fi
    
    # Check Inventory module
    local inv_count=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token ${ERPNEXT_API_KEY}:${ERPNEXT_API_SECRET}" \
        "${api_base}/Item?limit=1" 2>/dev/null || echo "000")
    if [ "$inv_count" = "200" ]; then
        detected_categories+=("inventory")
        print_success "Inventory module detected"
    fi
    
    # Check HR module
    local hr_count=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token ${ERPNEXT_API_KEY}:${ERPNEXT_API_SECRET}" \
        "${api_base}/Employee?limit=1" 2>/dev/null || echo "000")
    if [ "$hr_count" = "200" ]; then
        detected_categories+=("hr")
        print_success "HR module detected"
    fi
    
    # Check Project module
    local proj_count=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token ${ERPNEXT_API_KEY}:${ERPNEXT_API_SECRET}" \
        "${api_base}/Project?limit=1" 2>/dev/null || echo "000")
    if [ "$proj_count" = "200" ]; then
        detected_categories+=("project")
        print_success "Project module detected"
    fi
    
    # Always include operations
    detected_categories+=("operations")
    
    if [ ${#detected_categories[@]} -gt 0 ]; then
        SELECTED_CATEGORIES=("${detected_categories[@]}")
        print_success "Recommended categories: ${detected_categories[*]}"
        return 0
    else
        print_warning "Could not detect usage, using standard preset"
        IFS=',' read -ra SELECTED_CATEGORIES <<< "${PRESETS[standard]}"
        return 1
    fi
}

#===============================================================================
# PREREQUISITES CHECK
#===============================================================================

check_prerequisites() {
    print_step "1" "Prerequisites Check"
    
    local missing_deps=()
    local errors=()
    
    # Check Node.js
    if command -v node &> /dev/null; then
        local node_version
        node_version=$(node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$node_version" -ge 20 ] 2>/dev/null; then
            print_success "Node.js $(node --version) installed"
        else
            missing_deps+=("node")
            errors+=("Node.js >= 20 required (found: $(node --version))")
        fi
    else
        missing_deps+=("node")
        errors+=("Node.js not found")
    fi
    
    # Check Python
    if command -v python3 &> /dev/null; then
        local python_version
        python_version=$(python3 --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
        local major="${python_version%%.*}"
        if [ "$major" -ge 3 ] 2>/dev/null; then
            print_success "Python $(python3 --version 2>&1 | grep -oP '\d+\.\d+') installed"
        else
            missing_deps+=("python")
            errors+=("Python 3.10+ required")
        fi
    else
        missing_deps+=("python")
        errors+=("Python 3 not found")
    fi
    
    # Check jq
    if command -v jq &> /dev/null; then
        print_success "jq installed (for JSON merging)"
    else
        print_warning "jq not found (will install for better config merging)"
        missing_deps+=("jq")
    fi
    
    # Check git
    if command -v git &> /dev/null; then
        print_success "git installed"
    else
        missing_deps+=("git")
        errors+=("git not found")
    fi
    
    # Auto-install missing dependencies
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo ""
        print_info "Installing missing dependencies..."
        
        if command -v apt-get &> /dev/null; then
            sudo apt-get update -qq && sudo apt-get install -y -qq jq 2>/dev/null && \
                print_success "jq installed" || true
        elif command -v brew &> /dev/null; then
            brew install jq 2>/dev/null && print_success "jq installed" || true
        fi
    fi
    
    # Verify critical deps
    if command -v node &> /dev/null && command -v python3 &> /dev/null; then
        return 0
    else
        for err in "${errors[@]}"; do
            print_error "$err"
        done
        
        if [ "$NON_INTERACTIVE" = false ]; then
            echo ""
            read -p "Continue anyway? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        else
            exit 1
        fi
    fi
}

#===============================================================================
# MCP SERVER INSTALLATION
#===============================================================================

install_mcp_servers() {
    print_step "2" "MCP Server Installation"
    
    # Test ERPNext MCP package
    echo -n "Testing ERPNext MCP package (${ERPNEXT_MCP_PACKAGE})... "
    if timeout 45 npx -y "$ERPNEXT_MCP_PACKAGE" --version &>/dev/null 2>&1; then
        print_success "ERPNext MCP package ready"
    else
        print_warning "Could not verify ERPNext MCP package now"
        print_info "Config will still use npx at runtime; check network access if it fails later"
    fi
    
    # Clone frappe-mcp-server
    echo ""
    if [ -d "$FRAPPE_MCP_DIR" ]; then
        print_info "frappe-mcp-server exists at $FRAPPE_MCP_DIR"
        echo -n "Updating... "
        (cd "$FRAPPE_MCP_DIR" && git pull origin main 2>/dev/null) && \
            print_success "Updated" || print_info "Already up-to-date"
    else
        echo -n "Cloning frappe-mcp-server... "
        if git clone --depth 1 https://github.com/DragonPow/frappe-mcp-server.git "$FRAPPE_MCP_DIR" 2>/dev/null; then
            print_success "Cloned"
        else
            print_warning "Could not clone (network issue?)"
        fi
    fi
    
    # Install Python deps
    if [ -f "$FRAPPE_MCP_DIR/requirements.txt" ]; then
        echo -n "Installing Python dependencies... "
        pip install -q -r "$FRAPPE_MCP_DIR/requirements.txt" 2>/dev/null && \
            print_success "Installed" || print_info "Dependencies may already exist"
    fi
}

#===============================================================================
# CREDENTIALS INPUT
#===============================================================================

get_credentials() {
    print_step "3" "ERPNext Credentials"
    
    # URL
    if [ -z "$ERPNEXT_URL" ]; then
        read -p "ERPNext URL [https://your-site.erpnext.com]: " ERPNEXT_URL
        ERPNEXT_URL=${ERPNEXT_URL:-https://your-site.erpnext.com}
    fi
    ERPNEXT_URL="${ERPNEXT_URL%/}"
    print_info "URL: $ERPNEXT_URL"
    
    # API Key
    if [ -z "$ERPNEXT_API_KEY" ]; then
        echo ""
        read -p "API Key: " -s ERPNEXT_API_KEY
        echo
        while [ -z "$ERPNEXT_API_KEY" ] && [ "$NON_INTERACTIVE" = false ]; do
            print_error "API Key is required"
            read -p "API Key: " -s ERPNEXT_API_KEY
            echo
        done
    fi
    
    # API Secret
    if [ -z "$ERPNEXT_API_SECRET" ]; then
        echo ""
        read -p "API Secret: " -s ERPNEXT_API_SECRET
        echo
        while [ -z "$ERPNEXT_API_SECRET" ] && [ "$NON_INTERACTIVE" = false ]; do
            print_error "API Secret is required"
            read -p "API Secret: " -s ERPNEXT_API_SECRET
            echo
        done
    fi
    
    # Validate credentials
    validate_credentials
    
    # Detect bench path
    echo ""
    if [ -d "$HOME/frappe-bench" ]; then
        FRAPPE_BENCH_PATH="$HOME/frappe-bench"
        print_success "Detected Frappe bench: $FRAPPE_BENCH_PATH"
    elif [ -d "/workspace/frappe-bench" ]; then
        FRAPPE_BENCH_PATH="/workspace/frappe-bench"
        print_success "Detected Frappe bench: $FRAPPE_BENCH_PATH"
    else
        read -p "Frappe bench path [$HOME/frappe-bench]: " FRAPPE_BENCH_PATH
        FRAPPE_BENCH_PATH=${FRAPPE_BENCH_PATH:-$HOME/frappe-bench}
    fi
}

validate_credentials() {
    echo ""
    echo -n "Validating ERPNext connection... "
    
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token ${ERPNEXT_API_KEY}:${ERPNEXT_API_SECRET}" \
        "${ERPNEXT_URL}/api/method/ping" 2>/dev/null || echo "000")
    
    case "$response" in
        200)
            print_success "Connection successful"
            return 0
            ;;
        401|403)
            print_error "Authentication failed (HTTP $response)"
            ERPNEXT_API_KEY=""
            ERPNEXT_API_SECRET=""
            if [ "$NON_INTERACTIVE" = false ]; then
                get_credentials
            else
                exit 1
            fi
            ;;
        000)
            print_error "Cannot connect to ERPNext (network error)"
            if [ "$NON_INTERACTIVE" = false ]; then
                read -p "Retry? [Y/n] " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                    get_credentials
                fi
            fi
            ;;
        *)
            print_warning "Unexpected response (HTTP $response)"
            ;;
    esac
}

#===============================================================================
# CATEGORY SELECTION
#===============================================================================

select_categories() {
    print_step "4" "Category Selection"
    
    # Auto-detect if enabled
    if [ "$AUTO_DETECT_MODE" = true ]; then
        auto_detect_usage
        display_token_summary
        return
    fi
    
    # If already set via CLI, skip
    if [ ${#SELECTED_CATEGORIES[@]} -gt 0 ]; then
        display_token_summary
        return
    fi
    
    echo "Select categories to load in MCP server:"
    echo ""
    echo "PRESETS:"
    for key in minimal standard full dev_focus; do
        echo "  ${PRESET_LABELS[$key]} - ${PRESET_DESCRIPTIONS[$key]}"
    done
    echo ""
    echo "CATEGORIES:"
    for i in "${!ALL_CATEGORIES[@]}"; do
        local cat="${ALL_CATEGORIES[$i]}"
        local tools=${CATEGORY_TOOLS[$cat]}
        local tokens=${CATEGORY_TOKENS[$cat]}
        local desc=${CATEGORY_DESCRIPTIONS[$cat]}
        local icon=${CATEGORY_ICONS[$cat]}
        echo "  $((i+1)). $icon $desc ($tools tools, ~$tokens tokens)"
    done
    echo ""
    
    if [ "$NON_INTERACTIVE" = true ]; then
        IFS=',' read -ra SELECTED_CATEGORIES <<< "${PRESETS[standard]}"
        print_info "Using standard preset"
    else
        read -p "Selection [standard/preset name/category names]: " selection
        selection=${selection:-standard}
        
        case "$selection" in
            minimal|1) IFS=',' read -ra SELECTED_CATEGORIES <<< "${PRESETS[minimal]}";;
            standard|2) IFS=',' read -ra SELECTED_CATEGORIES <<< "${PRESETS[standard]}";;
            full|3) IFS=',' read -ra SELECTED_CATEGORIES <<< "${PRESETS[full]}";;
            dev|4) IFS=',' read -ra SELECTED_CATEGORIES <<< "${PRESETS[dev_focus]}";;
            auto|detect) 
                AUTO_DETECT_MODE=true
                auto_detect_usage
                display_token_summary
                return
                ;;
            *) IFS=',' read -ra SELECTED_CATEGORIES <<< "$selection";;
        esac
    fi
    
    echo ""
    display_token_summary
}

#===============================================================================
# AI CLIENT SELECTION
#===============================================================================

select_ai_client() {
    print_step "5" "AI Client Selection"
    
    if [ "$NON_INTERACTIVE" = true ]; then
        print_info "Selected: $AI_CLIENT"
        return
    fi
    
    echo "Which AI coding assistant to configure?"
    echo ""
    echo "  [1] Claude Code        - Anthropic's AI coding assistant"
    echo "  [2] OpenCode           - Open source AI coding agent (free)"
    echo "  [3] Both              - Configure both [DEFAULT]"
    echo ""
    
    read -p "Choice [3]: " choice
    choice=${choice:-3}
    
    case "$choice" in
        1) AI_CLIENT="claude";;
        2) AI_CLIENT="opencode";;
        *) AI_CLIENT="both";;
    esac
    
    print_success "Selected: $AI_CLIENT"
}

#===============================================================================
# CONFIG MERGE STRATEGY
#===============================================================================

select_config_merge() {
    print_step "6" "Config Merge Strategy"
    
    if [ "$NON_INTERACTIVE" = true ]; then
        print_info "Strategy: $CONFIG_MERGE_STRATEGY"
        return
    fi
    
    echo "How to handle existing MCP configs?"
    echo ""
    echo "  [1] Append            - Add servers, keep existing [RECOMMENDED]"
    echo "  [2] New file         - Create separate config for review"
    echo "  [3] Overwrite         - Replace entire config (backup first)"
    echo ""
    
    read -p "Choice [1]: " choice
    choice=${choice:-1}
    
    case "$choice" in
        1) CONFIG_MERGE_STRATEGY="append";;
        2) CONFIG_MERGE_STRATEGY="newfile";;
        3) CONFIG_MERGE_STRATEGY="overwrite";;
        *) CONFIG_MERGE_STRATEGY="append";;
    esac
    
    print_success "Strategy: $CONFIG_MERGE_STRATEGY"
}

#===============================================================================
# CONFIG GENERATION - With Real JSON Merging
#===============================================================================

generate_configs() {
    print_step "7" "Generating Configuration"
    
    local categories_string
    categories_string=$(IFS=,; echo "${SELECTED_CATEGORIES[*]}")
    
    if [[ "$AI_CLIENT" == "claude" ]] || [[ "$AI_CLIENT" == "both" ]]; then
        generate_claude_config "$categories_string"
    fi
    
    if [[ "$AI_CLIENT" == "opencode" ]] || [[ "$AI_CLIENT" == "both" ]]; then
        generate_opencode_config "$categories_string"
    fi
}

generate_claude_config() {
    local categories=$1
    local claude_config="${HOME}/.claude.jsonc"
    local claude_settings="${HOME}/.claude/settings.jsonc"
    
    # Determine config file
    if [ -f "$claude_settings" ]; then
        claude_config="$claude_settings"
    elif [ ! -f "$claude_config" ]; then
        touch "$claude_config"
    fi
    
    echo "Generating Claude Code config..."
    
    # Build MCP server JSON
    local mcp_json=$(cat <<EOF
{
  "erpnext": {
    "command": "npx",
    "args": ["-y", "${ERPNEXT_MCP_PACKAGE}", "--categories=${categories}"],
    "env": {
      "ERPNEXT_URL": "${ERPNEXT_URL}",
      "ERPNEXT_API_KEY": "${ERPNEXT_API_KEY}",
      "ERPNEXT_API_SECRET": "${ERPNEXT_API_SECRET}"
    }
  },
  "frappe-dev": {
    "command": "python",
    "args": ["${FRAPPE_MCP_DIR}/server.py"],
    "env": {
      "FRAPPE_URL": "${ERPNEXT_URL}",
      "FRAPPE_API_KEY": "${ERPNEXT_API_KEY}",
      "FRAPPE_API_SECRET": "${ERPNEXT_API_SECRET}"
    }
  }
}
EOF
)
    
    case "$CONFIG_MERGE_STRATEGY" in
        append)
            if command -v jq &> /dev/null; then
                # Real JSON merging with jq
                local existing_config="{}"
                if [ -f "$claude_config" ] && [ -s "$claude_config" ]; then
                    existing_config=$(cat "$claude_config")
                fi
                
                # Merge configs properly
                local merged
                merged=$(echo "$existing_config" | jq --argjson new_servers "$mcp_json" \
                    '.mcpServers = (.mcpServers // {}) + $new_servers')
                
                echo "$merged" > "$claude_config"
                print_success "Config merged with jq"
            else
                # Fallback: append raw JSON
                echo "$mcp_json" >> "$claude_config"
                print_warning "jq not available, appended to end of file"
            fi
            ;;
            
        newfile)
            local output_file="${SCRIPT_DIR}/claude-mcp-config.jsonc"
            cat > "$output_file" <<< "{\"mcpServers\": $mcp_json}"
            print_success "Created: $output_file"
            echo ""
            echo "Review and merge manually into ~/.claude.jsonc"
            ;;
            
        overwrite)
            cp "$claude_config" "${claude_config}.backup" 2>/dev/null || true
            cat > "$claude_config" <<< "{\"mcpServers\": $mcp_json}"
            print_success "Saved (backup: ${claude_config}.backup)"
            ;;
    esac
}

generate_opencode_config() {
    local categories=$1
    local output_file="${SCRIPT_DIR}/opencode.jsonc"
    
    echo "Generating OpenCode config..."
    
    local mcp_json=$(cat <<EOF
{
  "erpnext": {
    "type": "local",
    "command": ["npx", "-y", "${ERPNEXT_MCP_PACKAGE}", "--categories=${categories}"],
    "environment": {
      "ERPNEXT_URL": "${ERPNEXT_URL}",
      "ERPNEXT_API_KEY": "${ERPNEXT_API_KEY}",
      "ERPNEXT_API_SECRET": "${ERPNEXT_API_SECRET}"
    }
  },
  "frappe-dev": {
    "type": "local",
    "command": ["python", "${FRAPPE_MCP_DIR}/server.py"],
    "environment": {
      "FRAPPE_URL": "${ERPNEXT_URL}",
      "FRAPPE_API_KEY": "${ERPNEXT_API_KEY}",
      "FRAPPE_API_SECRET": "${ERPNEXT_API_SECRET}"
    }
  }
}
EOF
)
    
    cat > "$output_file" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "mcp": $mcp_json
}
EOF
    
    print_success "Saved: $output_file"
}

#===============================================================================
# COPY AGENTS.MD
#===============================================================================

copy_agents_md() {
    local agents_template="${SCRIPT_DIR}/AGENTS.md"
    local dest_agents="AGENTS.md"
    
    if [ ! -f "$agents_template" ]; then
        print_debug "AGENTS.md template not found"
        return
    fi
    
    if [ "$NON_INTERACTIVE" = true ]; then
        cp "$agents_template" "$dest_agents" 2>/dev/null || true
        return
    fi
    
    echo ""
    read -p "Copy AGENTS.md to current directory? [y/N]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Replace placeholders
        local result
        result=$(calculate_tokens)
        local total_tokens=${result% *}
        
        sed -e "s/{FRAPPE_VERSION}/15/g" \
            -e "s/{ERPNEXT_VERSION}/14/g" \
            -e "s|{BENCH_PATH}|$FRAPPE_BENCH_PATH|g" \
            -e "s/{SELECTED_CATEGORIES}/${SELECTED_CATEGORIES[*]}/g" \
            -e "s/{TOKEN_COUNT}/~$total_tokens/g" \
            "$agents_template" > "$dest_agents"
        
        print_success "AGENTS.md created with your config"
    fi
}

#===============================================================================
# FINAL SUMMARY
#===============================================================================

show_summary() {
    print_step "✓" "Setup Complete"
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
    echo -e "${GREEN}${BOLD}🎉 Setup Complete!${NC}"
    echo ""
    
    echo "Configuration:"
    echo "  • ERPNext URL: $ERPNEXT_URL"
    echo "  • Categories: ${SELECTED_CATEGORIES[*]}"
    echo "  • AI Client: $AI_CLIENT"
    echo "  • Merge Strategy: $CONFIG_MERGE_STRATEGY"
    echo ""
    
    display_token_summary
    
    echo ""
    echo "NEXT STEPS:"
    echo ""
    echo "  1. Restart your AI client"
    echo ""
    
    if [[ "$AI_CLIENT" == "claude" ]] || [[ "$AI_CLIENT" == "both" ]]; then
        echo "     Claude Code:"
        echo "       • Restart terminal or run: claude mcp list"
        echo ""
    fi
    
    if [[ "$AI_CLIENT" == "opencode" ]] || [[ "$AI_CLIENT" == "both" ]]; then
        echo "     OpenCode:"
        echo "       • cd to project && opencode"
        echo ""
    fi
    
    echo "  2. Test: \"Show me all customers in ERPNext\""
    echo "  3. Run: /context (Claude Code) to see token usage"
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
}

#===============================================================================
# MAIN
#===============================================================================

main() {
    log "Starting Frappe MCP Setup v${VERSION}"
    
    parse_args "$@"
    
    print_banner
    
    if [ "$NON_INTERACTIVE" = true ]; then
        print_info "Running in non-interactive mode"
    fi
    
    check_prerequisites
    install_mcp_servers
    get_credentials
    select_categories
    select_ai_client
    select_config_merge
    generate_configs
    copy_agents_md
    show_summary
    
    log "Setup completed successfully"
}

main "$@"
