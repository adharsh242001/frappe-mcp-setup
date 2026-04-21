#!/usr/bin/env python3
"""
Frappe MCP Server - Simple Python Implementation
"""

import os
import sys
import json
import asyncio

# Configuration
FRAPPE_URL = os.environ.get("FRAPPE_URL", "http://localhost:8000")
FRAPPE_API_KEY = os.environ.get("FRAPPE_API_KEY", "")
FRAPPE_API_SECRET = os.environ.get("FRAPPE_API_SECRET", "")

def main():
    """Run the MCP server"""
    from mcp.server import Server
    from mcp.server.stdio import stdio_server
    from mcp.types import Tool, TextContent
    
    server = Server("frappe-mcp")
    
    @server.list_tools()
    async def list_tools():
        return [
            Tool(
                name="frappe_ping",
                description="Ping Frappe server",
                inputSchema={"type": "object", "properties": {}}
            ),
            Tool(
                name="frappe_list_documents",
                description="List documents of a DocType",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "doctype": {"type": "string", "description": "DocType name"},
                        "limit": {"type": "integer", "description": "Max results", "default": 20}
                    },
                    "required": ["doctype"]
                }
            ),
            Tool(
                name="frappe_get_document",
                description="Get a document by name",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "doctype": {"type": "string"},
                        "name": {"type": "string"}
                    },
                    "required": ["doctype", "name"]
                }
            ),
        ]

    @server.call_tool()
    async def call_tool(name, arguments):
        import requests
        
        headers = {"Authorization": f"token {FRAPPE_API_KEY}:{FRAPPE_API_SECRET}"}
        
        try:
            if name == "frappe_ping":
                r = requests.get(f"{FRAPPE_URL}/api/method/ping", headers=headers, timeout=5)
                return [TextContent(type="text", text=r.text)]
            
            elif name == "frappe_list_documents":
                params = {"limit_page_length": arguments.get("limit", 20)}
                r = requests.get(
                    f"{FRAPPE_URL}/api/resource/{arguments['doctype']}",
                    headers=headers, params=params, timeout=10
                )
                return [TextContent(type="text", text=r.text)]
            
            elif name == "frappe_get_document":
                r = requests.get(
                    f"{FRAPPE_URL}/api/resource/{arguments['doctype']}/{arguments['name']}",
                    headers=headers, timeout=10
                )
                return [TextContent(type="text", text=r.text)]
            
            else:
                return [TextContent(type="text", text=f"Unknown tool: {name}")]
        
        except Exception as e:
            return [TextContent(type="text", text=f"Error: {str(e)}")]

    # Run server
    async def run():
        async with stdio_server() as (read, write):
            await server.run(read, write, server.create_initialization_options())

    asyncio.run(run())

if __name__ == "__main__":
    main()
