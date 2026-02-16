# Installation

## Prerequisites

This project uses [mise](https://mise.jdx.dev/) for tool version management and task running. Install it first:

```bash
curl https://mise.run | sh
```

## Setup

```bash
git clone <repo-url>
cd usaspending-mcp

# Install Elixir, Erlang, and mdbook (versions defined in mise.toml)
mise install

# Fetch dependencies and apply patches
mise run setup
```

`mise run setup` does three things:

1. Runs `mix deps.get` to fetch Hex packages
2. Patches a bug in `hermes_mcp`'s STDIO transport ([details](../architecture/overview.md#known-issues))
3. Recompiles the patched dependency

## Verify

Compile and run the tests:

```bash
mise run compile
mise run test
```

To verify the server starts and responds to MCP messages:

```bash
mise run docs:test
```

You should see JSON responses including a `tools/list` result with all 7 tools.

## Available tasks

Run `mise tasks` to see all available tasks:

```
mise run setup       # Fetch dependencies and apply patches
mise run server      # Start the MCP server
mise run compile     # Compile the project
mise run test        # Run the test suite
mise run docs        # Build the mdbook documentation
mise run docs:serve  # Serve docs locally with live reload
mise run docs:test   # Verify the server responds to MCP requests
```
