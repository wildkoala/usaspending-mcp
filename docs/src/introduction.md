# USASpending MCP Server

An [MCP](https://modelcontextprotocol.io/) server in Elixir that gives AI assistants access to the [USASpending.gov API](https://api.usaspending.gov) — the U.S. government's official source for federal spending data.

## What it does

This server exposes 7 tools that let an MCP client (like Claude) query federal spending data:

| Tool | What it does |
|------|-------------|
| `search_spending_by_award` | Search awards by keyword, date, agency, or type |
| `search_spending_by_award_count` | Count awards grouped by type |
| `get_spending_explorer` | Aggregate spending by budget function, agency, etc. |
| `list_agencies` | List all top-tier federal agencies with budgets |
| `get_award_details` | Get full details on a specific award |
| `get_recipient_profile` | Look up a spending recipient's profile |
| `list_federal_accounts` | Browse federal accounts and budgetary resources |

## How it works

The server communicates over **stdio** using the MCP JSON-RPC protocol. Claude Code (or any MCP client) launches it as a subprocess, sends tool requests over stdin, and reads responses from stdout.

No authentication is needed — the USASpending API is public.

## Quick start

```bash
git clone <repo-url> && cd usaspending-mcp
mise install      # install Elixir, Erlang, mdbook
mise run setup    # fetch deps + apply patches
```
