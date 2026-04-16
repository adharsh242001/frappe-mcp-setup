# Frappe MCP Setup - Technical Specification

## Overview

This document contains the complete technical specification for the Frappe/ERPNext MCP setup project.

---

## Project Structure

```
frappe-mcp-setup/
├── setup-frappe-mcp.sh              # Main installer script
│
├── includes/                         # Script includes (sourced functions)
│   ├── 01_prerequisites.sh          # Check & install dependencies
│   ├── 02_category_selector.sh      # Interactive TUI category picker
│   ├── 03_token_calculator.sh      # Real-time token calculation
│   ├── 04_config_generator.sh       # Generate AI client configs
│   ├── 05_verification.sh          # Test MCP connection
│   └── 06_ai_client_setup.sh       # Claude/OpenCode specific setup
│
├── templates/                       # Configuration templates
│   ├── claude_config.jsonc         # Claude Code template
│   ├── opencode_config.jsonc       # OpenCode template
│   └── agents_md_template.md       # AGENTS.md template
│
├── AGENTS.md                        # Project template (copy to projects)
├── SPEC.md                         # This file
└── README.md                       # User-facing documentation
```

---

## Prerequisites Detection & Installation

### Dependencies

| Dependency | Required Version | Purpose | Auto-Install |
|------------|-----------------|---------|--------------|
| Node.js | >= 20.0.0 | npx for npm MCP servers | Yes |
| Python | >= 3.10 | pip for Python MCP server | Yes |
| pip | latest | Install Python packages | Yes |
| git | any | Clone repositories | Check only |
| curl | any | Download scripts | Check only |
| dialog/whiptail | any | TUI GUI | Auto-install |

### Detection Logic

```bash
# Check Node.js
node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1

# Check Python
python3 --version 2>/dev/null | grep -oP '\d+\.\d+'

# Check GUI availability
if command -v dialog &> /dev/null; then
    DIALOG="dialog"
elif command -v whiptail &> /dev/null; then
    DIALOG="whiptail"
else
    # Auto-install dialog
    apt-get install -y dialog 2>/dev/null || brew install dialog
fi
```

---

## Category Selector Specification

### Data Structures

```bash
# Category definitions with actual token estimates
# Token estimates based on schema analysis: tokens = JSON.stringify(schema).length / 4

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
```

### Preset Definitions

```bash
declare -A PRESETS=(
    ["minimal"]="operations"
    ["standard"]="sales,inventory,operations"
    ["full"]="sales,purchasing,inventory,accounting,hr,project,delivery,manufacturing,crm,assets,operations,kanban,analytics,setup"
    ["dev_focus"]="operations,project,kanban"
)

declare -A PRESET_DESCRIPTIONS=(
    ["minimal"]="Quick edits, read-only, lowest token cost"
    ["standard"]="Balanced for most developers"
    ["full"]="All features, highest token cost"
    ["dev_focus"]="For Frappe developers"
)
```

### Token Calculation

```bash
calculate_tokens() {
    local total=0
    local tool_count=0

    for category in "${SELECTED_CATEGORIES[@]}"; do
        total=$((total + CATEGORY_TOKENS[$category]))
        tool_count=$((tool_count + CATEGORY_TOOLS[$category]))
    done

    echo "$total"
    echo "$tool_count"
}

get_token_rating() {
    local tokens=$1

    if [ "$tokens" -lt 10000 ]; then
        echo "✅ LEAN - Fast"
    elif [ "$tokens" -lt 25000 ]; then
        echo "⚠️  NORMAL - Average"
    else
        echo "❌ HEAVY - Slow"
    fi
}
```

### TUI Implementation

```bash
# Using dialog for TUI
dialog --checklist "Select categories:" \
    22 70 14 \
    "sales" "Sales (17 tools, ~4,760 tokens)" ON \
    "inventory" "Inventory (9 tools, ~2,070 tokens)" ON \
    "operations" "Operations (7 tools, ~1,750 tokens)" ON \
    # ... remaining categories
```

---

## Config Generation Specification

### Claude Code Config

**Location**: `~/.claude.jsonc` or `~/.claude/settings.jsonc`

**Merge strategies**:
1. **Append** (default): Add new servers, keep existing
2. **New file**: Create `frappe-mcp-config.jsonc` for review
3. **Overwrite**: Replace entire config (with backup)

**Generated config structure**:

```jsonc
{
  "mcpServers": {
    "erpnext": {
      "command": "npx",
      "args": ["-y", "@casys/mcp-erpnext", "--categories={SELECTED}"],
      "env": {
        "ERPNEXT_URL": "{URL}",
        "ERPNEXT_API_KEY": "{API_KEY}",
        "ERPNEXT_API_SECRET": "{API_SECRET}"
      }
    },
    "frappe-dev": {
      "command": "python",
      "args": ["/path/to/frappe-mcp-server/server.py"],
      "env": {
        "FRAPPE_URL": "{URL}",
        "FRAPPE_API_KEY": "{API_KEY}",
        "FRAPPE_API_SECRET": "{API_SECRET}"
      }
    }
  }
}
```

### OpenCode Config

**Location**: `opencode.jsonc` in project root or `~/.config/opencode/opencode.jsonc`

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "erpnext": {
      "type": "local",
      "command": ["npx", "-y", "@casys/mcp-erpnext", "--categories={SELECTED}"],
      "environment": {
        "ERPNEXT_URL": "{URL}",
        "ERPNEXT_API_KEY": "{API_KEY}",
        "ERPNEXT_API_SECRET": "{API_SECRET}"
      }
    }
  }
}
```

### Config Merge Logic

```bash
merge_config() {
    local strategy=$1
    local config_file=$2
    local new_config=$3

    case "$strategy" in
        "append")
            # Read existing, add new servers, keep existing
            jq -s '.[0] * {mcpServers: (.[0].mcpServers + .[1].mcpServers)}' \
                "$config_file" "$new_config" > "${config_file}.tmp"
            mv "${config_file}.tmp" "$config_file"
            ;;
        "new_file")
            cp "$new_config" "frappe-mcp-config.jsonc"
            echo "Created frappe-mcp-config.jsonc for review"
            ;;
        "overwrite")
            cp "$config_file" "${config_file}.backup"
            cp "$new_config" "$config_file"
            ;;
    esac
}
```

---

## Verification Specification

### Connection Test

```bash
verify_erpnext_connection() {
    local url=$1
    local api_key=$2
    local api_secret=$3

    # Test API access
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token ${api_key}:${api_secret}" \
        "${url}/api/method/ping")

    if [ "$response" = "200" ]; then
        echo "✅ ERPNext connection successful"
        return 0
    else
        echo "❌ ERPNext connection failed (HTTP $response)"
        return 1
    fi
}

verify_mcp_servers() {
    # For Claude Code
    claude mcp list 2>/dev/null | grep -q "erpnext" && echo "✅ erpnext MCP connected"
    claude mcp list 2>/dev/null | grep -q "frappe-dev" && echo "✅ frappe-dev MCP connected"

    # For OpenCode
    opencode mcp list 2>/dev/null | grep -q "erpnext" && echo "✅ erpnext MCP connected"
}
```

---

## Error Handling

### Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| E_NODE_MISSING | Node.js not found | Offer to install |
| E_PYTHON_MISSING | Python not found | Offer to install |
| E_GUI_MISSING | No TUI available | Fall back to CLI |
| E_URL_INVALID | Invalid ERPNext URL | Ask to re-enter |
| E_API_AUTH_FAILED | API authentication failed | Check credentials |
| E_CONFIG_WRITE | Config file write failed | Check permissions |
| E_GIT_CLONE | Repository clone failed | Check network |

### User Prompts

```bash
# On error, show clear message and options
echo -e "${RED}Error: ERPNext URL is not reachable${NC}"
echo ""
echo "Options:"
echo "  [1] Retry with different URL"
echo "  [2] Skip verification and continue"
echo "  [3] Exit setup"
read -p "Choose option [1]: " choice
```

---

## MCP Server Installation

### @casys/mcp-erpnext

**Installation method**: npx (no clone needed)

```bash
# Test installation
npx -y @casys/mcp-erpnext --version

# Run with specific categories
npx -y @casys/mcp-erpnext --categories=sales,inventory
```

### frappe-mcp-server

**Installation method**: Git clone + pip

```bash
# Clone repository
git clone https://github.com/DragonPow/frappe-mcp-server.git \
    "${HOME}/frappe-mcp-server"

# Install dependencies
cd "${HOME}/frappe-mcp-server"
pip install -r requirements.txt

# Build (if TypeScript)
npm install && npm run build
```

---

## User Flow

```
┌─────────────────────────────────────────────────────────────┐
│  START: Run setup script                                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 1: Prerequisites Check                               │
│  ├── Check Node.js >= 20                                   │
│  ├── Check Python >= 3.10                                  │
│  ├── Check/install dialog/whiptail                        │
│  └── Auto-install missing dependencies                     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 2: MCP Server Installation                          │
│  ├── Test @casys/mcp-erpnext via npx                      │
│  ├── Clone frappe-mcp-server                              │
│  └── Install Python dependencies                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 3: Credentials                                      │
│  ├── ERPNext URL (with validation)                        │
│  ├── API Key (masked input)                               │
│  ├── API Secret (masked input)                            │
│  └── Frappe Bench Path (auto-detect)                       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 4: Category Selection (TUI)                         │
│  ├── Show presets                                          │
│  ├── Display category checklist                           │
│  ├── Real-time token calculator                           │
│  └── Calculate total tokens                               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 5: AI Client Selection                             │
│  ├── [1] Claude Code                                     │
│  ├── [2] OpenCode                                        │
│  └── [3] Both                                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 6: Config Merge Strategy                           │
│  ├── [1] Append to existing (recommended)                 │
│  ├── [2] Create new file for review                      │
│  └── [3] Overwrite existing                              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 7: Config Generation                               │
│  ├── Generate configs                                     │
│  ├── Apply merge strategy                                 │
│  └── Create backup if needed                              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 8: Verification                                    │
│  ├── Test ERPNext API connection                          │
│  ├── List MCP servers                                     │
│  └── Show token usage summary                             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 9: Next Steps                                      │
│  ├── Restart AI client                                   │
│  ├── Test with sample query                               │
│  └── Copy AGENTS.md to project                            │
└─────────────────────────────────────────────────────────────┘
```

---

## Security Considerations

1. **API credentials**: Store securely, never commit to git
2. **Config files**: Add to `.gitignore` if containing secrets
3. **Environment variables**: Use for production deployments
4. **Rate limiting**: ERPNext has built-in rate limiting
5. **Permissions**: Use least-privilege ERPNext user for API

---

## Future Enhancements

- [ ] Docker-based MCP server deployment
- [ ] Remote MCP server for team sharing
- [ ] Custom category presets
- [ ] Token usage monitoring
- [ ] MCP server health checks
- [ ] Automatic updates
