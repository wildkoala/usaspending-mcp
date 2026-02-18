defmodule UsaspendingMcp.Tools.ListFederalAccounts do
  @moduledoc "List and search federal accounts with budgetary resource information"

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient

  schema do
    field :keyword, :string, description: "Keyword to search federal accounts by name or number"
    field :fiscal_year, :integer, description: "Fiscal year to filter by (e.g. 2024)"
    field :agency_identifier, :string, description: "Agency identifier code to filter accounts"

    field :sort_field, :string,
      description:
        "Field to sort by: account_name, account_number, budgetary_resources, or managing_agency (default: budgetary_resources)"

    field :sort_direction, :string, description: "Sort direction: asc or desc (default: desc)"
    field :page, :integer, description: "Page number (default 1)"
    field :limit, :integer, description: "Results per page (default 10, max 100)"
  end

  def execute(params, frame) do
    params = UsaspendingMcp.stringify_params(params)
    body =
      %{
        page: Map.get(params, "page", 1),
        limit: min(Map.get(params, "limit", 10), 100),
        sort: %{
          field: Map.get(params, "sort_field", "budgetary_resources"),
          direction: Map.get(params, "sort_direction", "desc")
        }
      }
      |> maybe_put(:keyword, Map.get(params, "keyword"))
      |> maybe_put(:filters, build_filters(params))

    case ApiClient.post("/api/v2/federal_accounts/", body) do
      {:ok, data} ->
        text = format_results(data)
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.text(text), frame}

      {:error, reason} ->
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.error(reason), frame}
    end
  end

  defp build_filters(params) do
    filters = %{}

    filters =
      case Map.get(params, "fiscal_year") do
        nil -> filters
        fy -> Map.put(filters, :fiscal_year, fy)
      end

    case Map.get(params, "agency_identifier") do
      nil -> filters
      id -> Map.put(filters, :agency_identifier, id)
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, val) when val == %{}, do: map
  defp maybe_put(map, key, val), do: Map.put(map, key, val)

  defp format_results(%{"results" => results, "page_metadata" => meta}) do
    total = meta["total"] || 0
    page = meta["page"] || 1

    header = "Federal Accounts (#{total} total, page #{page}):\n\n"

    rows =
      Enum.map_join(results, "\n---\n", fn account ->
        """
        #{account["account_name"] || "N/A"}
          Account Number: #{account["account_number"] || "N/A"}
          Managing Agency: #{account["managing_agency"] || account["managing_agency_acronym"] || "N/A"}
          Budgetary Resources: #{format_currency(account["budgetary_resources"])}\
        """
      end)

    header <> rows
  end

  defp format_results(data), do: Jason.encode!(data, pretty: true)

  defp format_currency(nil), do: "N/A"

  defp format_currency(amount) when is_number(amount),
    do: "$#{:erlang.float_to_binary(amount / 1, decimals: 2)}"

  defp format_currency(amount), do: "$#{amount}"
end
