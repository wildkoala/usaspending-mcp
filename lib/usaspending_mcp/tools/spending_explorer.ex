defmodule UsaspendingMcp.Tools.SpendingExplorer do
  @moduledoc """
  Explore aggregate federal spending breakdowns by budget function, agency, object class, or federal account for a given fiscal year.

  Returns the top spending entries for the chosen dimension, with dollar amounts. This gives a high-level view of where federal money goes within a fiscal year.

  Both 'type' and 'fiscal_year' are REQUIRED parameters. The type must be one of: budget_function, agency, object_class, or federal_account. The fiscal_year must be an integer (e.g. 2024, 2025). The optional spending_type defaults to "total" but can be set to "discretionary" or "mandatory".

  Use this tool when the user asks broad questions like "where does the government spend money?" or "which agencies spend the most?" For award-level detail, use search_spending_by_award instead.
  """

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient
  alias UsaspendingMcp.Responses.SpendingExplorerResponse
  import UsaspendingMcp.Formatter, only: [format_currency: 1]

  schema do
    field :type, {:required, :string},
      description:
        "Dimension to break spending down by: budget_function, agency, object_class, or federal_account"

    field :fiscal_year, {:required, :integer}, description: "Fiscal year (e.g. 2024)"

    field :spending_type, :string,
      description: "Type of spending: total, discretionary, or mandatory (default: total)"
  end

  def execute(params, frame) do
    params = UsaspendingMcp.stringify_params(params)
    body = %{
      type: params["type"],
      filters: %{
        fiscal_year: params["fiscal_year"],
        spending_type: Map.get(params, "spending_type", "total")
      }
    }

    case ApiClient.post("/api/v2/spending/", body) do
      {:ok, data} ->
        text = format_results(data, params["type"])
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.text(text), frame}

      {:error, reason} ->
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.error(reason), frame}
    end
  end

  defp format_results(data, type) do
    case SpendingExplorerResponse.from_map(data) do
      %SpendingExplorerResponse{results: results, total: total} ->
        header = "Spending by #{type} (Total: #{format_currency(total)}):\n\n"

        rows =
          results
          |> Enum.sort_by(& &1.amount, :desc)
          |> Enum.take(25)
          |> Enum.map_join("\n", fn item ->
            name = item.name || item.code || "Unknown"
            amount = format_currency(item.amount)
            "  #{name}: #{amount}"
          end)

        header <> rows

      nil ->
        Jason.encode!(data, pretty: true)
    end
  end
end
