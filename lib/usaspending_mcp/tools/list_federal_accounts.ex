defmodule UsaspendingMcp.Tools.ListFederalAccounts do
  @moduledoc """
  List and search federal Treasury accounts with their budgetary resource amounts and managing agency information.

  Returns a paginated list of federal accounts with: account name, account number, managing agency, and budgetary resources amount. All parameters are optional — call with no arguments to get accounts sorted by budgetary resources descending.

  Use the keyword parameter to search accounts by name or number. Use agency_identifier to filter to a specific agency's accounts. Use fiscal_year to see a specific year's budgetary resources.

  This tool is for exploring federal financial accounts. For award-level spending data, use search_spending_by_award instead.
  """

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient
  alias UsaspendingMcp.Responses.FederalAccountListResponse
  import UsaspendingMcp.Formatter, only: [format_currency: 1]

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

  defp format_results(data) do
    case FederalAccountListResponse.from_map(data) do
      %FederalAccountListResponse{accounts: accounts, total: total, page: page} ->
        header = "Federal Accounts (#{total} total, page #{page}):\n\n"

        rows =
          Enum.map_join(accounts, "\n---\n", fn account ->
            """
            #{account.account_name || "N/A"}
              Account Number: #{account.account_number || "N/A"}
              Managing Agency: #{account.managing_agency || account.managing_agency_acronym || "N/A"}
              Budgetary Resources: #{format_currency(account.budgetary_resources)}\
            """
          end)

        header <> rows

      nil ->
        Jason.encode!(data, pretty: true)
    end
  end
end
