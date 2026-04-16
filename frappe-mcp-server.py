#!/usr/bin/env python3
"""
Frappe MCP Server - Python Implementation
Connects Claude Code/OpenCode to Frappe/ERPNext via REST API
"""

import os
import sys
import json
import requests
from typing import Any

try:
    from mcp.server import Server
    from mcp.server.stdio import stdio_server
    from mcp.types import Tool, TextContent
    from mcp.server.handlers import list_tools_handler, call_tool_handler
except ImportError:
    print("Error: MCP library not installed", file=sys.stderr)
    print("Run: pip install mcp", file=sys.stderr)
    sys.exit(1)

# Configuration from environment
FRAPPE_URL = os.environ.get("FRAPPE_URL", "http://localhost:8000")
FRAPPE_API_KEY = os.environ.get("FRAPPE_API_KEY", "")
FRAPPE_API_SECRET = os.environ.get("FRAPPE_API_SECRET", "")

# Create MCP Server
server = Server("frappe-mcp")

def frappe_api_call(method: str, endpoint: str, data: dict = None) -> dict:
    """Make authenticated call to Frappe REST API"""
    url = f"{FRAPPE_URL}/api/{endpoint}"
    headers = {
        "Authorization": f"token {FRAPPE_API_KEY}:{FRAPPE_API_SECRET}",
        "Content-Type": "application/json"
    }
    
    try:
        if method == "GET":
            response = requests.get(url, headers=headers, params=data)
        elif method == "POST":
            response = requests.post(url, headers=headers, json=data)
        elif method == "PUT":
            response = requests.put(url, headers=headers, json=data)
        elif method == "DELETE":
            response = requests.delete(url, headers=headers)
        else:
            return {"error": f"Unknown method: {method}"}
        
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        return {"error": str(e)}

# Define available tools
@server.list_tools()
async def list_tools() -> list[Tool]:
    """List available Frappe/ERPNext tools"""
    return [
        Tool(
            name="frappe_ping",
            description="Ping Frappe server to check connection",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        Tool(
            name="frappe_list_documents",
            description="List documents of a specific DocType",
            inputSchema={
                "type": "object",
                "properties": {
                    "doctype": {"type": "string", "description": "DocType name (e.g., Customer, Sales Order)"},
                    "filters": {"type": "string", "description": "JSON filters (optional)"},
                    "fields": {"type": "string", "description": "Comma-separated fields (optional)"},
                    "limit": {"type": "integer", "description": "Max results (default 20)", "default": 20}
                },
                "required": ["doctype"]
            }
        ),
        Tool(
            name="frappe_get_document",
            description="Get a single document by name",
            inputSchema={
                "type": "object",
                "properties": {
                    "doctype": {"type": "string", "description": "DocType name"},
                    "name": {"type": "string", "description": "Document name"}
                },
                "required": ["doctype", "name"]
            }
        ),
        Tool(
            name="frappe_create_document",
            description="Create a new document",
            inputSchema={
                "type": "object",
                "properties": {
                    "doctype": {"type": "string", "description": "DocType name"},
                    "data": {"type": "string", "description": "JSON document data"}
                },
                "required": ["doctype", "data"]
            }
        ),
        Tool(
            name="frappe_update_document",
            description="Update an existing document",
            inputSchema={
                "type": "object",
                "properties": {
                    "doctype": {"type": "string", "description": "DocType name"},
                    "name": {"type": "string", "description": "Document name"},
                    "data": {"type": "string", "description": "JSON with fields to update"}
                },
                "required": ["doctype", "name", "data"]
            }
        ),
        Tool(
            name="frappe_delete_document",
            description="Delete a document (must be draft)",
            inputSchema={
                "type": "object",
                "properties": {
                    "doctype": {"type": "string", "description": "DocType name"},
                    "name": {"type": "string", "description": "Document name"}
                },
                "required": ["doctype", "name"]
            }
        ),
        Tool(
            name="frappe_get_documents_count",
            description="Get count of documents matching filters",
            inputSchema={
                "type": "object",
                "properties": {
                    "doctype": {"type": "string", "description": "DocType name"},
                    "filters": {"type": "string", "description": "JSON filters (optional)"}
                },
                "required": ["doctype"]
            }
        ),
        Tool(
            name="frappe_run_doc_method",
            description="Run a document method",
            inputSchema={
                "type": "object",
                "properties": {
                    "doctype": {"type": "string", "description": "DocType name"},
                    "name": {"type": "string", "description": "Document name"},
                    "method": {"type": "string", "description": "Method name to run"},
                    "args": {"type": "string", "description": "JSON arguments (optional)"}
                },
                "required": ["doctype", "name", "method"]
            }
        ),
        Tool(
            name="frappe_execute_server_script",
            description="Execute a Server Script",
            inputSchema={
                "type": "object",
                "properties": {
                    "script": {"type": "string", "description": "Script name"},
                    "data": {"type": "string", "description": "JSON data (optional)"}
                },
                "required": ["script"]
            }
        )
    ]

@server.call_tool()
async def call_tool(name: str, arguments: Any) -> list[TextContent]:
    """Handle tool calls"""
    try:
        if name == "frappe_ping":
            result = frappe_api_call("GET", "method/ping")
            return [TextContent(type="text", text=json.dumps(result, indent=2))]
        
        elif name == "frappe_list_documents":
            doctype = arguments.get("doctype")
            filters = arguments.get("filters")
            fields = arguments.get("fields")
            limit = arguments.get("limit", 20)
            
            params = {"limit_page_length": limit}
            if filters:
                params["filters"] = filters
            if fields:
                params["fields"] = json.dumps(fields.split(","))
            
            result = frappe_api_call("GET", f"resource/{doctype}", params)
            return [TextContent(type="text", text=json.dumps(result, indent=2))]
        
        elif name == "frappe_get_document":
            doctype = arguments.get("doctype")
            docname = arguments.get("name")
            result = frappe_api_call("GET", f"resource/{doctype}/{docname}")
            return [TextContent(type="text", text=json.dumps(result, indent=2))]
        
        elif name == "frappe_create_document":
            doctype = arguments.get("doctype")
            data = json.loads(arguments.get("data", "{}"))
            data["doctype"] = doctype
            result = frappe_api_call("POST", f"resource/{doctype}", data)
            return [TextContent(type="text", text=json.dumps(result, indent=2))]
        
        elif name == "frappe_update_document":
            doctype = arguments.get("doctype")
            docname = arguments.get("name")
            data = json.loads(arguments.get("data", "{}"))
            result = frappe_api_call("PUT", f"resource/{doctype}/{docname}", data)
            return [TextContent(type="text", text=json.dumps(result, indent=2))]
        
        elif name == "frappe_delete_document":
            doctype = arguments.get("doctype")
            docname = arguments.get("name")
            result = frappe_api_call("DELETE", f"resource/{doctype}/{docname}")
            return [TextContent(type="text", text=json.dumps(result, indent=2))]
        
        elif name == "frappe_get_documents_count":
            doctype = arguments.get("doctype")
            filters = arguments.get("filters")
            params = {"limit_page_length": 0}
            if filters:
                params["filters"] = filters
            result = frappe_api_call("GET", f"resource/{doctype}", params)
            count = len(result.get("data", []))
            return [TextContent(type="text", text=f"Total documents: {count}")]
        
        elif name == "frappe_run_doc_method":
            doctype = arguments.get("doctype")
            docname = arguments.get("name")
            method = arguments.get("method")
            args = arguments.get("args", "{}")
            data = {"args": args}
            result = frappe_api_call("POST", f"method/{doctype}.{method}", data)
            return [TextContent(type="text", text=json.dumps(result, indent=2))]
        
        elif name == "frappe_execute_server_script":
            script = arguments.get("script")
            data = arguments.get("data", "{}")
            body = {"data": json.loads(data) if data else {}}
            result = frappe_api_call("POST", f"method/run_server_script", body)
            return [TextContent(type="text", text=json.dumps(result, indent=2))]
        
        else:
            return [TextContent(type="text", text=f"Unknown tool: {name}")]
    
    except Exception as e:
        return [TextContent(type="text", text=f"Error: {str(e)}")]

async def main():
    """Main entry point"""
    print(f"[frappe-mcp] Starting server...", file=sys.stderr)
    print(f"[frappe-mcp] Frappe URL: {FRAPPE_URL}", file=sys.stderr)
    
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            server.create_initialization_options()
        )

if __name__ == "__main__":
    asyncio.run(main()) if hasattr(asyncio, 'run') else main()
