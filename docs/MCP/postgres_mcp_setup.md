# Postgres MCP Server Setup Guide

This guide explains how to set up the Postgres MCP Server to allow your AI assistant to interact with your local `ohmyword_dev` database.

## Prerequisites

- Node.js & `npx` installed (You have v10.7.0).
- PostgreSQL running locally.

## Quick Start (Command Line)

You can run the MCP server directly from your terminal to test it:

```bash
npx -y @modelcontextprotocol/server-postgres "postgresql://postgres:postgres@localhost:5432/ohmyword_dev"
```

## Permanent Configuration (for IDEs/Agents)

To make this server available to your AI assistant (like Cursor, Claude Desktop, or other MCP clients), you typically need to add it to a configuration file (often `mcp.json` or similar settings).

### Configuration Snippet

Add this to your MCP configuration:

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://postgres:postgres@localhost:5432/ohmyword_dev"
      ]
    }
  }
}
```

### Where to put this?

- **Claude Desktop:** `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Cursor:** Check your Cursor settings or `.cursor/mcp.json` (if supported in your version).
- **General MCP Clients:** Look for a "Servers" or "Config" section.

## Verification

Once configured:
1.  Restart your AI client/IDE.
2.  Ask the AI: "Show me the tables in the database."
3.  If successful, it should list your `users`, `schema_migrations`, etc.
