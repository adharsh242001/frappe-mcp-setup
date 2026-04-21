# Frappe/ERPNext MCP Setup

AI-assisted development setup for Frappe and ERPNext. This repository configures MCP servers for Claude Code and OpenCode so your agent can query ERPNext data, create or inspect documents, and use Frappe development context while working in your project.

## What Gets Installed

| MCP server | Source | Purpose |
| --- | --- | --- |
| `erpnext` | `github:Casys-AI/mcp-erpnext` via `npx` | ERPNext data operations, reports, and module-specific tools |
| `frappe` | `DragonPow/frappe-mcp-server` | Frappe development context, DocType help, hooks, bench guidance |

The setup script can write config for Claude Code, OpenCode, or both.

## Requirements

- Bash-compatible shell
- `curl`
- `git`
- Node.js 20 or newer, for the ERPNext MCP package
- Python 3.10 or newer, for the Frappe development MCP server
- `jq`, recommended for safe JSON config merging
- ERPNext URL plus API key and API secret

## Get ERPNext API Keys

1. Log in to ERPNext.
2. Open **User Menu -> My Settings**.
3. Scroll to **API Access**.
4. Click **Generate Keys**.
5. Copy the API key and API secret.

Use an account with only the permissions your agent should have.

## Quick Start

Install the setup project:

```bash
curl -fsSL https://raw.githubusercontent.com/adharsh242001/frappe-mcp-setup/main/install.sh | bash
```

Then run the interactive setup:

```bash
cd ~/frappe-mcp-setup
./setup-frappe-mcp.sh
```

The script will:

1. Check local dependencies.
2. Ask for ERPNext URL and API credentials.
3. Let you choose ERPNext tool categories.
4. Clone or update the Frappe MCP server.
5. Generate Claude Code and/or OpenCode MCP config.
6. Create an `AGENTS.md` helper file for Frappe/ERPNext projects.

By default, the ERPNext MCP package is loaded from `https://github.com/Casys-AI/mcp-erpnext.git` using the npm package spec `github:Casys-AI/mcp-erpnext`.

## Non-Interactive Setup

Use this for repeatable local setup, containers, or CI environments:

```bash
cd ~/frappe-mcp-setup
./setup-frappe-mcp.sh --non-interactive \
  --url "https://your-site.erpnext.com" \
  --api-key "your-api-key" \
  --api-secret "your-api-secret" \
  --preset standard \
  --client both
```

You can also select categories directly:

```bash
./setup-frappe-mcp.sh --non-interactive \
  --url "https://your-site.erpnext.com" \
  --api-key "your-api-key" \
  --api-secret "your-api-secret" \
  --categories sales,inventory,operations \
  --client claude
```

To use a different package source, set `ERPNEXT_MCP_PACKAGE` before running setup:

```bash
ERPNEXT_MCP_PACKAGE="@casys/mcp-erpnext" ./setup-frappe-mcp.sh
```

## Auto-Detect Categories

Auto-detect scans your ERPNext instance and chooses categories based on enabled or active modules:

```bash
./setup-frappe-mcp.sh --non-interactive \
  --url "https://your-site.erpnext.com" \
  --api-key "your-api-key" \
  --api-secret "your-api-secret" \
  --auto-detect
```

## Category Presets

Choose the smallest preset that covers your current work. Smaller presets keep agent context faster and cheaper.

| Preset | Categories | Estimated tokens |
| --- | --- | --- |
| `minimal` | `operations` | ~1,750 |
| `standard` | `sales,inventory,operations` | ~8,480 |
| `dev_focus` | `operations,project,kanban` | ~4,330 |
| `full` | All categories | ~26,760 |

Available categories:

```text
sales,purchasing,inventory,accounting,hr,project,delivery,manufacturing,crm,assets,operations,kanban,analytics,setup
```

## Generated Config

### Claude Code

The script writes MCP server entries to `~/.claude/settings.jsonc` when that file exists, otherwise to `~/.claude.jsonc`.

Example shape:

```jsonc
{
  "mcpServers": {
    "erpnext": {
      "command": "npx",
      "args": ["-y", "github:Casys-AI/mcp-erpnext", "--categories=sales,inventory,operations"],
      "env": {
        "ERPNEXT_URL": "https://your-site.erpnext.com",
        "ERPNEXT_API_KEY": "your-api-key",
        "ERPNEXT_API_SECRET": "your-api-secret"
      }
    },
    "frappe": {
      "command": "python",
      "args": ["~/frappe-mcp-server/server.py"],
      "env": {
        "FRAPPE_URL": "https://your-site.erpnext.com",
        "FRAPPE_API_KEY": "your-api-key",
        "FRAPPE_API_SECRET": "your-api-secret"
      }
    }
  }
}
```

Restart Claude Code after setup, then verify:

```bash
claude mcp list
```

### OpenCode

The script writes `opencode.jsonc` in the setup directory.

Start OpenCode from that directory or copy the config into the project where you want to use it:

```bash
cd ~/frappe-mcp-setup
opencode
```

## Command Reference

```bash
./setup-frappe-mcp.sh [OPTIONS]

Options:
  --non-interactive, -y  Run without prompts
  --verbose, -v          Enable verbose output
  --url URL              ERPNext URL
  --api-key KEY          ERPNext API key
  --api-secret SECRET    ERPNext API secret
  --categories CATS      Comma-separated categories
  --preset NAME          minimal | standard | dev_focus | full
  --client CLIENT        claude | opencode | both
  --merge STRATEGY       append | newfile | overwrite
  --auto-detect          Scan ERPNext and select categories
  --help, -h             Show help
```

## Using the MCP Servers

After setup, ask your agent for ERPNext and Frappe tasks in plain language:

```text
Show me open Sales Orders from this month.
Check stock balance for Stores - Company.
Create a draft Customer record for ABC Corp.
Explain how to add a validate hook to Sales Order.
Create a custom DocType for project milestones.
```

For write operations, verify the target document and state first. Prefer draft documents while testing, and avoid submitting, cancelling, or bulk-changing production data until you have reviewed the action.

## Lightweight Python MCP Server

This repo also includes `frappe-mcp-server.py`, a small fallback MCP server with three tools:

- `frappe_ping`
- `frappe_list_documents`
- `frappe_get_document`

Use it when you only need basic Frappe REST access or cannot use the cloned `DragonPow/frappe-mcp-server`.

Install dependencies in the Python environment you want Claude Code or OpenCode to use:

```bash
python -m pip install mcp requests
```

Claude Code example:

```jsonc
{
  "mcpServers": {
    "frappe-basic": {
      "command": "python",
      "args": ["/absolute/path/to/frappe-mcp-server.py"],
      "env": {
        "FRAPPE_URL": "http://localhost:8000",
        "FRAPPE_API_KEY": "your-api-key",
        "FRAPPE_API_SECRET": "your-api-secret"
      }
    }
  }
}
```

## Troubleshooting

### MCP Server Does Not Appear

Check the generated config and restart your AI client:

```bash
claude mcp list
```

For OpenCode, make sure you start it from the directory containing `opencode.jsonc`, or place the config in your target project.

### Authentication Fails

- Confirm the ERPNext URL has no typo and is reachable from your machine.
- Regenerate the API key and secret from the ERPNext user settings.
- Confirm the user has permission for the DocTypes or reports you are asking the agent to access.

### Node.js Version Error

The ERPNext MCP package requires Node.js 20 or newer. Upgrade Node.js, then rerun:

```bash
./setup-frappe-mcp.sh
```

### Token Usage Is Too High

Use a smaller preset:

```bash
./setup-frappe-mcp.sh --preset minimal
```

You can add more categories later by rerunning the setup script.

## Credits

- [`Casys-AI/mcp-erpnext`](https://github.com/Casys-AI/mcp-erpnext)
- [`DragonPow/frappe-mcp-server`](https://github.com/DragonPow/frappe-mcp-server)

## License

MIT
