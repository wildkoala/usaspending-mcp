defmodule UsaspendingMcp.Tools.SpendingExplorer do
  @moduledoc "Explore aggregate federal spending breakdowns by budget function, agency, object class, or federal account for a given fiscal year"

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient

  schema do
    field :type, {:required, :string},
      description:
        "Dimension to break spending down by: budget_function, agency, object_class, or federal_account"

    field :fiscal_year, {:required, :integer}, description: "Fiscal year (e.g. 2024)"

    field :spending_type, :string,
      description: "Type of spending: total, discretionary, or mandatory (default: total)"
  end

  def execute(params, frame) do
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

  defp format_results(%{"results" => results, "total" => total}, type) do
    header = "Spending by #{type} (Total: #{format_currency(total)}):\n\n"

    rows =
      results
      |> Enum.sort_by(& &1["amount"], :desc)
      |> Enum.take(25)
      |> Enum.map_join("\n", fn item ->
        name = item["name"] || item["code"] || "Unknown"
        amount = format_currency(item["amount"])
        "  #{name}: #{amount}"
      end)

    header <> rows
  end

  defp format_results(data, _type), do: Jason.encode!(data, pretty: true)

  defp format_currency(nil), do: "N/A"

  defp format_currency(amount) when is_number(amount),
    do: "$#{:erlang.float_to_binary(amount / 1, decimals: 2)}"

  defp format_currency(amount), do: "$#{amount}"
end
