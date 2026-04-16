# 🚀 Frappe/ERPNext MCP Setup

**AI-powered development setup for Frappe/ERPNext with Claude Code & OpenCode**

One-command setup that configures MCP servers with token-aware category selection, auto-detect ERPNext usage, and intelligent JSON config merging.

## ⚡ Quick Start

### One-liner (fastest)

```bash
curl -fsSL https://raw.githubusercontent.com/adharsh242001/frappe-mcp-setup/main/install.sh | bash
```

### Or with inline arguments

```bash
curl -fsSL https://raw.githubusercontent.com/adharsh242001/frappe-mcp-setup/main/install.sh | bash -s -- \
  --non-interactive \
  --url "https://erp.example.com" \
  --api-key "your-api-key" \
  --api-secret "your-api-secret" \
  --preset standard \
  --client both
```

### Manual Setup

```bash
git clone https://github.com/adharsh242001/frappe-mcp-setup.git
cd frappe-mcp-setup
chmod +x setup-frappe-mcp.sh
./setup-frappe-mcp.sh
```

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Token Calculator** | Real token estimates based on schema analysis |
| **Auto-Detect** | Scan ERPNext instance to suggest categories |
| **Smart Merging** | jq-based JSON merging, preserves existing configs |
| **Non-Interactive Mode** | Full automation support for CI/CD |
| **Error Handling** | Retry logic, validation, clear error messages |

## 🎯 What You Get

### MCP Servers

| Server | Tools | Purpose |
|--------|-------|---------|
| `@casys/mcp-erpnext` | 120 | ERPNext data operations, CRUD, analytics |
| `frappe-mcp-server` | 6 | Frappe development context, DocType creation |

### AI Clients

- **Claude Code** - Anthropic's AI coding assistant
- **OpenCode** - Open source AI coding agent

## 📊 Token Presets

| Preset | Categories | Est. Tokens | Use Case |
|--------|------------|------------|----------|
| `minimal` | Operations | ~1,750 | Quick edits |
| `standard` | Sales + Inventory + Operations | ~8,480 | Most developers |
| `full` | All 14 categories | ~26,760 | Power users |
| `dev_focus` | Operations + Project + Kanban | ~4,330 | Frappe developers |

## 🔧 Usage Examples

### Interactive Setup

```bash
./setup-frappe-mcp.sh
```

### Non-Interactive (CI/CD)

```bash
./setup-frappe-mcp.sh --non-interactive \
  --url "https://erp.example.com" \
  --api-key "xxx" \
  --api-secret "yyy" \
  --categories sales,inventory \
  --client claude
```

### Auto-Detect Usage

```bash
./setup-frappe-mcp.sh --auto-detect
```

## 📁 Generated Files

```
project/
├── opencode.jsonc          # OpenCode MCP config
├── AGENTS.md               # AI agent guidelines
└── .claude.jsonc          # Claude Code MCP config (if configured)
```

## 🔐 API Keys Setup

1. Login to ERPNext
2. User Menu → My Settings
3. API Access → Generate Keys
4. Copy API Key and API Secret

## 🛠️ Command Line Options

```bash
./setup-frappe-mcp.sh [OPTIONS]

Options:
  --non-interactive, -y    Non-interactive mode
  --verbose, -v            Verbose output
  --url URL                ERPNext URL
  --api-key KEY            API Key
  --api-secret SECRET      API Secret
  --categories CATS        Comma-separated categories
  --preset NAME            Preset (minimal/standard/full/dev_focus)
  --client CLIENT          claude/opencode/both
  --merge STRATEGY         append/newfile/overwrite
  --auto-detect            Auto-detect ERPNext usage
  --help, -h               Show help
```

## 📖 Documentation

- [SPEC.md](SPEC.md) - Technical specification
- [AGENTS.md](AGENTS.md) - AI agent guidelines template

## 🤝 Contributing

Contributions welcome! Please read the SPEC.md for technical details.

## 📄 License

MIT License

## 🙏 Credits

- [@casys/mcp-erpnext](https://github.com/Casys-AI/mcp-erpnext) - 120 ERPNext tools
- [DragonPow/frappe-mcp-server](https://github.com/DragonPow/frappe-mcp-server) - Frappe development context
