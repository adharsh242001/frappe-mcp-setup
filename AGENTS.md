# Frappe/ERPNext Development Agent

This file provides context and guidelines for AI coding assistants working on this Frappe/ERPNext project.

## Project Configuration

```yaml
frappe_version: "{FRAPPE_VERSION}"
erpnext_version: "{ERPNEXT_VERSION}"
bench_path: "{BENCH_PATH}"
custom_apps:
  - {APP_NAME}
site_name: "{SITE_NAME}"
```

## MCP Servers Available

### @casys/mcp-erpnext (Data Operations)

**Purpose**: Read/write ERPNext data, run reports, query documents

**Categories loaded**: {SELECTED_CATEGORIES}
**Estimated token cost**: ~{TOKEN_COUNT}

#### When to Use

- Querying existing data (customers, sales orders, inventory)
- Creating or updating documents
- Running reports (stock balance, sales analytics)
- Checking document states

#### Available Tools

| Category | Tools | Use Case |
|----------|-------|----------|
| Sales | 17 | Customers, Orders, Invoices, Quotations |
| Inventory | 9 | Items, Stock, Warehouses |
| Operations | 7 | Generic CRUD for any DocType |
| {ADDITIONAL} | | |

#### Example Usage

```
To get all open sales orders:
→ erpnext_sales_order_list(status="Open")

To check stock balance:
→ erpnext_stock_balance(warehouse="Stores - Company")

To create a new customer:
→ erpnext_customer_create(name="ABC Corp", group="Commercial")
```

---

### frappe-dev (Development Context)

**Purpose**: Understand Frappe architecture, create DocTypes, run bench commands

**Purpose**: Frappe development assistance, DocType creation, bench commands

#### When to Use

- Creating new DocTypes
- Understanding Frappe hooks and events
- Running bench commands (migrate, console, etc.)
- Accessing Frappe API documentation
- Understanding ORM operations

#### Available Resources

- `ORM_CHEATSHEET` - `frappe.get_doc`, `frappe.db.get_all`, etc.
- `HOOKS_CHEATSHEET` - Document events, scheduler events, hooks
- `FRONTEND_API_CHEATSHEET` - `frappe.ui.Dialog`, `frm`, client scripts
- `BENCH_CHEATSHEET` - CLI commands
- `UTILITIES_CHEATSHEET` - Caching, email, background jobs

#### Example Usage

```
To create a new DocType:
→ frappe_create_doctype(app_name="my_app", doctype_name="Project Task", fields=[...])

To run migrations:
→ bench --site {SITE} migrate
```

---

## Development Workflow

### Standard Feature Implementation

1. **Understand the requirement**
   - Read existing DocTypes and data structure
   - Check related documents using erpnext MCP

2. **Plan the implementation**
   - Create DocType JSON definition
   - Plan controller logic
   - Identify hooks needed

3. **Implement**
   - Create DocType using frappe-dev MCP
   - Write controller code
   - Add hooks

4. **Test**
   - Run bench commands
   - Verify in ERPNext UI
   - Test with sample data

### Data Migration Pattern

1. Export data using erpnext tools
2. Transform to new format
3. Import using erpnext_doc_create

---

## Coding Conventions

### DocType Naming

- Use PascalCase: `CustomerOrder`, `ProjectTask`
- Singular nouns: `Item`, not `Items`
- Prefix custom with app name: `MyAppCustomerOrder`

### Field Naming

- snake_case: `customer_name`, `order_date`
- Be descriptive: `total_amount` not `total`
- Use appropriate fieldtypes (Link, Data, Int, etc.)

### Hooks Usage

```python
# hooks.py
doc_events = {
    "Sales Order": {
        "on_submit": "my_app.utils.on_sales_order_submit",
        "validate": "my_app.utils.validate_sales_order"
    }
}
```

---

## Safety Rules

### DO

- ✅ Verify document state before submit/cancel
- ✅ Use draft status for testing
- ✅ Backup data before bulk operations
- ✅ Test in development environment first
- ✅ Review generated code before applying
- ✅ Use transactions for critical operations

### DON'T

- ❌ Never submit/cancel without verification
- ❌ Don't delete submitted documents
- ❌ Don't run migrate during business hours
- ❌ Don't ignore validation errors
- ❌ Don't skip testing edge cases

---

## Useful Commands

### Bench Commands

```bash
# Migrate after DocType changes
bench --site {SITE} migrate

# Clear cache
bench --site {SITE} clear-cache

# Enter Python console
bench --site {SITE} console

# Run tests
bench run-tests --app {APP}

# List sites
bench list-sites
```

### Frappe Commands

```python
# In bench console
frappe.get_doc("DocType", "name")
frappe.db.get_all("DocType", filters={...})
frappe.get_doc({
    "doctype": "DocType",
    "field": "value"
}).insert()

# Commit transaction
frappe.db.commit()

# Rollback if error
frappe.db.rollback()
```

---

## Token-Saving Tips

1. **Load categories selectively** - Only enable categories you need
2. **Disable unused MCP servers** - Set `enabled: false` in config
3. **Use minimal preset** - For simple tasks, use Operations only
4. **Per-project configs** - Different projects may need different setups

---

## Environment Variables

```bash
# ERPNext Connection
ERPNEXT_URL=https://your-site.erpnext.com
ERPNEXT_API_KEY=your-api-key
ERPNEXT_API_SECRET=your-api-secret

# Frappe Path
FRAPPE_PATH=/path/to/frappe-bench
```

---

## Troubleshooting

### MCP Server Not Responding

1. Check ERPNext is accessible
2. Verify API credentials
3. Restart AI client
4. Run `claude mcp list` to check status

### "Tool not found" Error

- Ensure MCP server is enabled
- Check if category is loaded
- Verify config has correct category list

### Slow Responses

- Reduce number of categories loaded
- Consider using minimal preset
- Check network latency to ERPNext

---

## Additional Resources

- [Frappe Framework Documentation](https://frappeframework.com/docs)
- [ERPNext User Manual](https://docs.erpnext.com)
- [Frappe Forum](https://discuss.frappe.io)
- [MCP Protocol](https://modelcontextprotocol.io)
