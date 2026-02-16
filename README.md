# USASpending MCP Server

An MCP (Model Context Protocol) server in Elixir that provides access to the [USASpending.gov API](https://api.usaspending.gov) — the U.S. government's source for federal spending data.

## Tools

| Tool | Description |
|------|-------------|
| `search_spending_by_award` | Search for federal spending awards with filters (keywords, dates, agency, award type) |
| `search_spending_by_award_count` | Get counts of awards grouped by type (Contracts, Grants, Loans, etc.) |
| `get_spending_explorer` | Explore aggregate spending by budget function, agency, object class, or federal account |
| `list_agencies` | List top-tier federal agencies with budget and spending data |
| `get_award_details` | Get detailed information about a specific award |
| `get_recipient_profile` | Get profile for a spending recipient (location, business type, spending breakdown) |
| `list_federal_accounts` | List and search federal accounts with budgetary resources |

## Setup

Requires [mise](https://mise.jdx.dev/) for tool and task management.

```bash
mise install   # install Elixir, Erlang, mdbook
mise run setup # fetch deps + apply patches
```

## Available tasks

```
mise run setup       # Fetch dependencies and apply patches
mise run server      # Start the MCP server
mise run compile     # Compile the project
mise run test        # Run the test suite
mise run docs        # Build the mdbook documentation
mise run docs:serve  # Serve docs locally with live reload
mise run docs:test   # Verify the server responds to MCP requests
```

## Usage with Claude Code

Add to `~/.claude/mcp_servers.json`:

```json
{
  "mcpServers": {
    "usaspending": {
      "command": "mise",
      "args": ["run", "server"],
      "cwd": "/path/to/usaspending-mcp"
    }
  }
}
```

## Architecture

- **`Hermes.Server`** — MCP protocol handling via [hermes_mcp](https://hex.pm/packages/hermes_mcp)
- **STDIO transport** — JSON-RPC over stdin/stdout
- **`Req`** — HTTP client for USASpending API calls
- **No authentication required** — USASpending API is public
