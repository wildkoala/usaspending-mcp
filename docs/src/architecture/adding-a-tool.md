# Adding a New Tool

This guide walks through adding a new MCP tool backed by a USASpending API endpoint.

## 1. Create the tool module

Create a new file in `lib/usaspending_mcp/tools/`. Here's a minimal template:

```elixir
defmodule UsaspendingMcp.Tools.MyNewTool do
  @moduledoc "Short description of what this tool does"

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient

  schema do
    field :required_param, {:required, :string}, description: "A required parameter"
    field :optional_param, :integer, description: "An optional parameter"
  end

  def execute(params, frame) do
    case ApiClient.get("/api/v2/some/endpoint/", param: params["required_param"]) do
      {:ok, data} ->
        text = format_result(data)
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.text(text), frame}

      {:error, reason} ->
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.error(reason), frame}
    end
  end

  defp format_result(data) do
    # Format the API response as readable text
    inspect(data)
  end
end
```

## 2. Register the component

Add a `component` line to `lib/usaspending_mcp/server.ex`:

```elixir
component UsaspendingMcp.Tools.MyNewTool, name: "my_new_tool"
```

The `name` option sets the tool name exposed to MCP clients.

## 3. Schema field types

The `schema` block uses the [Peri](https://hex.pm/packages/peri) validation DSL:

```elixir
schema do
  # Required string
  field :name, {:required, :string}, description: "..."

  # Optional integer
  field :page, :integer, description: "..."

  # Required list of strings
  field :codes, {:required, {:list, :string}}, description: "..."

  # Optional string (no extra metadata needed)
  field :query, :string, description: "..."
end
```

Available types: `:string`, `:integer`, `:float`, `:boolean`, `{:list, type}`.

Use `{:required, type}` to mark a field as required.

The `description` option is important — it's what the MCP client shows to the AI model.

## 4. Response patterns

### Success with text

```elixir
{:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.text("result"), frame}
```

### Error

```elixir
{:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.error("message"), frame}
```

## 5. Using the API client

For **GET** endpoints with query parameters:

```elixir
ApiClient.get("/api/v2/endpoint/", param1: "value", param2: 42)
```

For **POST** endpoints with a JSON body:

```elixir
ApiClient.post("/api/v2/endpoint/", %{filters: %{keyword: "search"}, page: 1})
```

Both return `{:ok, decoded_json}` or `{:error, reason_string}`.

## 6. Formatting responses

Format API responses as plain text rather than returning raw JSON. This makes the output more useful to AI models. See existing tools for patterns — typically a header line followed by structured key-value pairs.

## 7. Test

Compile and verify the new tool appears:

```bash
mise run compile
mise run docs:test
```

Your new tool should appear in the `tools/list` response.

## USASpending API reference

Endpoint contracts are documented in the USASpending API repository:

[`usaspending_api/api_contracts/contracts/v2/`](https://github.com/fedspendingtransparency/usaspending-api/tree/master/usaspending_api/api_contracts/contracts/v2)

The interactive endpoint docs are at: [api.usaspending.gov/docs/endpoints](https://api.usaspending.gov/docs/endpoints)
