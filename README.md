# 🚀 Frappe/ERPNext MCP Setup

### AI-Powered Development for Frappe/ERPNext

Connect Claude Code or OpenCode to your ERPNext instance with **one command**. Get 120+ tools for data operations, DocType creation, and Frappe development context.

---

## ⚡ One-Click Setup (30 seconds)

```bash
curl -fsSL https://raw.githubusercontent.com/adharsh242001/frappe-mcp-setup/main/install.sh | bash
```

**That's it.** The script will:
1. Install dependencies
2. Ask for your ERPNext URL & API keys
3. Configure Claude Code + OpenCode with MCP servers
4. Show token estimates for your selected categories

---

## 🔑 Before You Start

Get your ERPNext API keys:

1. Login to ERPNext
2. Click **User Menu → My Settings**
3. Scroll to **API Access**
4. Click **Generate Keys**
5. Copy **API Key** and **API Secret**

---

## 📋 Setup Options

### Option 1: Interactive (Recommended for first time)

```bash
curl -fsSL https://raw.githubusercontent.com/adharsh242001/frappe-mcp-setup/main/install.sh | bash
```

You'll be guided through:
- ERPNext URL & credentials
- Category selection with token calculator
- AI client choice (Claude Code/OpenCode/Both)

### Option 2: Non-Interactive (For automation)

```bash
curl -fsSL https://raw.githubusercontent.com/adharsh242001/frappe-mcp-setup/main/install.sh | bash -s -- \
  --url "https://your-site.erpnext.com" \
  --api-key "your-api-key" \
  --api-secret "your-api-secret" \
  --preset standard \
  --client both
```

### Option 3: Auto-Detect (Smart)

```bash
curl -fsSL https://raw.githubusercontent.com/adharsh242001/frappe-mcp-setup/main/install.sh | bash -s -- \
  --url "https://your-site.erpnext.com" \
  --api-key "your-api-key" \
  --api-secret "your-api-secret" \
  --auto-detect
```

The script scans your ERPNext instance and automatically selects the right categories based on what modules you're using.

---

## ✨ Features

| Feature | What It Does |
|---------|--------------|
| **Token Calculator** | Shows exact token cost before you commit |
| **Auto-Detect** | Scans ERPNext to suggest categories |
| **Smart Merge** | Adds MCP servers without breaking existing configs |
| **120+ Tools** | Full ERPNext CRUD, reports, analytics |
| **Frappe Context** | DocType creation, bench commands, hooks docs |

---

## 🎯 What You Get

### MCP Servers

| Server | Tools | What It Does |
|--------|-------|--------------|
| `@casys/mcp-erpnext` | 120 | ERPNext data: customers, orders, inventory, reports |
| `frappe-mcp-server` | 6 resources | Frappe docs: ORM, hooks, bench commands |

### AI Clients

| Client | Cost | Best For |
|--------|------|----------|
| **Claude Code** | Subscription | Complex agentic workflows |
| **OpenCode** | Free | Quick edits, local development |

---

## 📊 Token Presets

Choose how much context you want. More tokens = more capabilities but higher API cost.

| Preset | Categories | Est. Tokens | Speed |
|--------|------------|-------------|-------|
| `minimal` | Operations only | ~1,750 | ⚡ Fast |
| `standard` ⭐ | Sales + Inventory + Operations | ~8,480 | ⚡ Fast |
| `dev_focus` | Operations + Project + Kanban | ~4,330 | ⚡ Fast |
| `full` | All 14 categories | ~26,760 | 🐢 Normal |

> 💡 **Pro tip:** Start with `standard`, add categories as needed.

---

## 💬 Usage Examples

After setup, just talk to your AI:

```
"Show me all open Sales Orders from this month"
"Create a Customer Portal DocType with dashboard"
"Run a stock balance report for the main warehouse"
"Add a custom field to Sales Order for project reference"
```

---

## 🔧 Manual Installation

```bash
git clone https://github.com/adharsh242001/frappe-mcp-setup.git
cd frappe-mcp-setup
chmod +x setup-frappe-mcp.sh
./setup-frappe-mcp.sh
```

---

## 🛠️ Command Reference

```bash
./setup-frappe-mcp.sh [OPTIONS]

Options:
  --non-interactive     Skip all prompts (CI/CD)
  --url URL             ERPNext URL
  --api-key KEY        API Key
  --api-secret SECRET  API Secret
  --preset NAME        minimal | standard | dev_focus | full
  --categories CATS    Comma-separated: sales,inventory,hr
  --client CLIENT      claude | opencode | both
  --merge STRATEGY     append | newfile | overwrite
  --auto-detect        Scan ERPNext to auto-select categories
  --help, -h           Show this help
```

---

## 📁 After Setup

```
Your Project/
├── opencode.jsonc          # MCP config (auto-created)
├── AGENTS.md               # AI guidelines (optional)
└── ~/.claude.jsonc         # Claude Code config
```

---

## ❓ Troubleshooting

**MCP not connecting?**
```bash
# Check status
claude mcp list

# Restart Claude Code terminal
```

**Token cost too high?**
- Use `--preset minimal` to reduce categories
- Check `/context` in Claude Code for usage

**Need help?**
- [Frappe Forum](https://discuss.frappe.io)
- [MCP Protocol](https://modelcontextprotocol.io)

---

## 🙏 Credits

Built with love for the Frappe/ERPNext community.

- [@casys/mcp-erpnext](https://github.com/Casys-AI/mcp-erpnext) - 120 ERPNext tools
- [DragonPow/frappe-mcp-server](https://github.com/DragonPow/frappe-mcp-server) - Frappe context

---

## 📄 License

MIT License - Use it, modify it, share it.

---

<p align="center">
  <strong>Star the repo if this helped you!</strong><br>
  <a href="https://github.com/adharsh242001/frappe-mcp-setup">⭐ GitHub</a>
</p>
