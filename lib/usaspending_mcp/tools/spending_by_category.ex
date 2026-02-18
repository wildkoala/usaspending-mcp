defmodule UsaspendingMcp.Tools.SpendingByCategory do
  @moduledoc "Find which agencies, subagencies, or other categories have the most spending for a given NAICS code, PSC code, or other filters"

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient

  alias UsaspendingMcp.Types.{
    AdvancedFilterObject,
    AgencyObject,
    NAICSCodeObject,
    TimePeriodObject
  }

  schema do
    field :category, {:required, :string},
      description:
        "What to group results by: awarding_agency, awarding_subagency, funding_agency, funding_subagency, naics, psc, recipient_duns, cfda, country, state_territory, county, district, federal_account"

    field :naics_codes, {:list, :string},
      description: "NAICS codes to filter by (e.g. [\"541511\"] or prefix like [\"54\"])"

    field :psc_codes, {:list, :string},
      description: "Product/Service codes to filter by (e.g. [\"D306\", \"D399\"])"

    field :keywords, :string, description: "Search keywords"

    field :agency, :string, description: "Filter to a specific awarding agency name"

    field :start_date, :string, description: "Start date (YYYY-MM-DD)"
    field :end_date, :string, description: "End date (YYYY-MM-DD)"

    field :award_type_codes, {:list, :string},
      description:
        "Filter by award type codes. Contracts: A, B, C, D. Grants: 02, 03, 04, 05. Loans: 07, 08. Direct payments: 06, 10. Other: 09, 11"

    field :page, :integer, description: "Page number (default: 1)"
    field :limit, :integer, description: "Results per page (default: 10)"
  end

  def execute(params, frame) do
    params = UsaspendingMcp.stringify_params(params)

    filters =
      build_filters(params)
      |> AdvancedFilterObject.to_map()

    body = %{
      category: params["category"],
      filters: filters,
      spending_level: "transactions",
      page: Map.get(params, "page", 1),
      limit: min(Map.get(params, "limit", 10), 100)
    }

    case ApiClient.post("/api/v2/search/spending_by_category", body) do
      {:ok, data} ->
        text = format_results(data)
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.text(text), frame}

      {:error, reason} ->
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.error(reason), frame}
    end
  end

  defp build_filters(params) do
    agencies =
      case AgencyObject.from_params(Map.put(params, "agency_type", "awarding")) do
        [] -> nil
        list -> list
      end

    %AdvancedFilterObject{
      keywords: if(params["keywords"], do: [params["keywords"]]),
      time_period: build_time_period(params),
      agencies: agencies,
      award_type_codes: params["award_type_codes"],
      naics_codes: if(params["naics_codes"], do: NAICSCodeObject.require(params["naics_codes"])),
      psc_codes: params["psc_codes"]
    }
  end

  defp build_time_period(params) do
    case {params["start_date"], params["end_date"]} do
      {nil, nil} ->
        nil

      {start_date, end_date} ->
        [
          TimePeriodObject.new(
            start_date || "2007-10-01",
            end_date || Date.to_string(Date.utc_today())
          )
        ]
    end
  end

  defp format_results(%{"category" => category, "results" => results} = data) do
    total = get_in(data, ["page_metadata", "total"]) || length(results)
    page = get_in(data, ["page_metadata", "page"]) || 1

    header = "Spending by #{category} (#{total} results, page #{page}):\n\n"

    rows =
      Enum.map_join(results, "\n---\n", fn item ->
        """
        #{item["name"] || "Unknown"}#{if item["code"], do: " (#{item["code"]})", else: ""}
          Amount: #{format_currency(item["amount"])}
          Outlays: #{format_currency(item["total_outlays"])}\
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
