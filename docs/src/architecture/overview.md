# Architecture Overview

## Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| MCP protocol | [hermes_mcp](https://hex.pm/packages/hermes_mcp) | JSON-RPC handling, tool registration, stdio transport |
| HTTP client | [Req](https://hex.pm/packages/req) | Calls to the USASpending API |
| Runtime | Elixir/OTP | Supervision tree, process management |

## Project structure

```
lib/
  usaspending_mcp.ex                 # Root module
  usaspending_mcp/
    application.ex                   # OTP application — starts supervisor tree
    server.ex                        # Hermes.Server — registers all tool components
    api_client.ex                    # HTTP wrapper for USASpending API
    tools/
      search_spending_by_award.ex    # Tool: search awards
      search_spending_by_award_count.ex
      spending_explorer.ex           # Tool: aggregate spending
      list_agencies.ex               # Tool: agency list
      get_award_details.ex           # Tool: award details
      get_recipient_profile.ex       # Tool: recipient profile
      list_federal_accounts.ex       # Tool: federal accounts
config/
  config.exs                         # Logger configuration
docs/                                # This documentation (mdbook)
```

## Supervision tree

```
UsaspendingMcp.Supervisor (one_for_one)
  ├── Hermes.Server.Registry          # Process registry for server components
  └── Hermes.Server.Supervisor        # Manages server + transport
        ├── Task.Supervisor            # Async task management
        ├── Session.Supervisor         # MCP session lifecycle
        ├── Hermes.Server.Base         # Core server (tool dispatch)
        └── Hermes.Server.Transport.STDIO  # stdin/stdout JSON-RPC
```

## Request flow

1. MCP client writes a JSON-RPC message to **stdin**
2. `Hermes.Server.Transport.STDIO` reads the line and decodes it
3. The transport dispatches to `Hermes.Server.Base` via GenServer call
4. The server matches the tool name and calls the corresponding component's `execute/2`
5. The tool component builds an API request via `UsaspendingMcp.ApiClient`
6. `ApiClient` makes an HTTP request to `https://api.usaspending.gov`
7. The API response is formatted into human-readable text
8. The text is wrapped in an MCP tool response and written to **stdout**

## Key modules

### `UsaspendingMcp.Server`

Defines the MCP server using `Hermes.Server`. Registers all tool components at compile time:

```elixir
use Hermes.Server,
  name: "usaspending",
  version: "0.1.0",
  capabilities: [:tools]

component UsaspendingMcp.Tools.SearchSpendingByAward, name: "search_spending_by_award"
# ... more components
```

### `UsaspendingMcp.ApiClient`

Thin wrapper around `Req` with two functions:
- `get(path, params)` — GET request with query parameters
- `post(path, body)` — POST request with JSON body

Both return `{:ok, decoded_body}` or `{:error, reason}`.

### Tool components

Each tool is a module using `Hermes.Server.Component` with:
- A `schema do ... end` block defining input parameters
- An `execute(params, frame)` callback that calls the API and formats the response

## Known issues

### hermes_mcp STDIO transport bug

`hermes_mcp` v0.14.1 has a bug where `Message.decode/1` returns a list of messages but the STDIO transport's `process_message/2` expects a single map. This causes a `BadMapError` on every incoming message.

`mise run setup` patches this automatically by replacing:

```elixir
process_message(messages, state)
```

with:

```elixir
Enum.each(messages, &process_message(&1, state))
```

If you run `mix deps.get` manually, you need to re-run `mise run setup` to reapply the patch.
