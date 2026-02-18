defmodule UsaspendingMcp do
  @moduledoc """
  MCP server for querying the USASpending.gov federal spending API.
  """

  @doc "Normalize param keys to strings, handling both atom and string keys from hermes_mcp."
  def stringify_params(params) when is_map(params) do
    Map.new(params, fn {k, v} -> {to_string(k), v} end)
  end
end
