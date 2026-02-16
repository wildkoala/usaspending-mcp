# Configuration

## Claude Code

Add the server to `~/.claude/mcp_servers.json`:

```json
{
  "mcpServers": {
    "usaspending": {
      "command": "mise",
      "args": ["run", "server"],
      "cwd": "/absolute/path/to/usaspending-mcp"
    }
  }
}
```

Since mise manages the Elixir/Erlang toolchain, this works regardless of whether `mix` is on your system PATH.

## Other MCP clients

Any MCP client that supports stdio transport can use this server. The launch command is:

```bash
mise run server
```

The server reads JSON-RPC messages from stdin (one per line) and writes responses to stdout.

## Logger configuration

By default, logging is set to `:error` level in `config/config.exs` to prevent log output on stderr from interfering with MCP clients. To enable debug logging during development:

```elixir
# config/config.exs
config :logger, level: :debug
```

Debug logs go to stderr so they won't corrupt the MCP protocol on stdout.
