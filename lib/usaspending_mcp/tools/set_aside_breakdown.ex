defmodule UsaspendingMcp.Tools.SetAsideBreakdown do
  @moduledoc """
  Calculate what percentage of total spending goes to each small business set-aside category for given filters. Returns a complete breakdown across all set-aside types in a single call — no follow-up tool calls needed.

  Set-aside categories analyzed: HBCUs/Minority Institutions, HUBZone, Native American, Small Disadvantaged Business, Veteran Owned, and Women Owned. Each category's dollar amount and percentage of the base total is returned.

  The 'category' parameter is REQUIRED and determines the grouping dimension for the base spending query. Valid values: awarding_agency, awarding_subagency, funding_agency, funding_subagency, naics, psc, recipient_duns, cfda, country, state_territory, county, district, federal_account.

  This tool makes multiple API calls internally (one per set-aside category plus one baseline) so it may take longer than other tools. All filter parameters except category are optional. Dates must be in YYYY-MM-DD format. The agency parameter must be the full official toptier agency name.

  Use this when the user asks questions like "what percentage of DoD contracts go to veteran-owned businesses?" or "how does small business set-aside spending break down for NAICS 541511?"
  """

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient

  alias UsaspendingMcp.Types.{
    AdvancedFilterObject,
    AgencyObject,
    NAICSCodeObject,
    TimePeriodObject
  }

  import UsaspendingMcp.Formatter, only: [format_currency: 1]

  @set_aside_categories [
    {"HBCUs/Minority Institutions", ["HMT", "HMP"]},
    {"HUBZone", ["HZC", "HZS"]},
    {"Native American", ["BI", "ISEE", "ISBEE"]},
    {"Small Disadvantaged Business", ["SBP", "8AN", "HS3", "HS2Civ", "8A", "VSBCiv", "RSBCiv", "SBA", "ESB", "8ACCiv"]},
    {"Veteran Owned", ["SDVOSBC", "SDVOSBS", "VSA", "VSS"]},
    {"Women Owned", ["EDWOSBSS", "EDWOSB", "WOSBSS", "WOSB"]}
  ]

  schema do
    field :category, {:required, :string},
      description:
        "What to group results by: awarding_agency, awarding_subagency, funding_agency, funding_subagency, naics, psc, recipient_duns, cfda, country, state_territory, county, district, federal_account"

    field :naics_codes, {:list, :string},
      description: "NAICS codes to filter by (e.g. [\"541511\"] or prefix like [\"54\"])"

    field :psc_codes, {:list, :string},
      description: "Product/Service codes to filter by (e.g. [\"D306\", \"D399\"])"

    field :keywords, :string, description: "Search keywords"
    field :agency, :string, description: "Filter to a specific awarding toptier agency name (e.g. 'Department of Defense')"
    field :subagency, :string, description: "Filter to a specific awarding subtier agency name (e.g. 'Department of the Air Force')"
    field :start_date, :string, description: "Start date (YYYY-MM-DD)"
    field :end_date, :string, description: "End date (YYYY-MM-DD)"

    field :award_type_codes, {:list, :string},
      description:
        "Filter by award type codes. Contracts: A, B, C, D. Grants: 02, 03, 04, 05. Loans: 07, 08. Direct payments: 06, 10. Other: 09, 11"
  end

  def execute(params, frame) do
    params = UsaspendingMcp.stringify_params(params)
    base_filter = build_base_filter(params)
    category = params["category"]

    # Build all queries: base (no set-aside) + one per set-aside category
    queries =
      [{:base, nil} | Enum.map(@set_aside_categories, fn {name, codes} -> {name, codes} end)]

    results =
      Task.async_stream(
        queries,
        fn {label, codes} ->
          filter =
            if codes do
              %{base_filter | set_aside_type_codes: codes}
            else
              base_filter
            end

          filters = AdvancedFilterObject.to_map(filter)

          body = %{
            category: category,
            filters: filters,
            spending_level: "transactions",
            page: 1,
            limit: 100
          }

          case ApiClient.post("/api/v2/search/spending_by_category", body) do
            {:ok, %{"results" => items}} ->
              total = items |> Enum.map(& &1["amount"]) |> Enum.reject(&is_nil/1) |> Enum.sum()
              {label, total}

            {:ok, _} ->
              {label, 0}

            {:error, _} ->
              {label, 0}
          end
        end,
        max_concurrency: 7,
        timeout: 60_000
      )
      |> Enum.map(fn {:ok, result} -> result end)

    {_, base_total} = Enum.find(results, fn {label, _} -> label == :base end)
    category_results = Enum.reject(results, fn {label, _} -> label == :base end)

    text = format_breakdown(base_total, category_results)
    {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.text(text), frame}
  end

  defp build_base_filter(params) do
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
        default_start = Date.utc_today() |> Date.add(-4 * 365) |> Date.to_string()

        [
          TimePeriodObject.new(
            start_date || default_start,
            end_date || Date.to_string(Date.utc_today())
          )
        ]
    end
  end

  defp format_breakdown(base_total, _category_results) when base_total == 0 do
    "No spending found for the given filters.\n\n" <>
      "Set-aside breakdown could not be calculated (base total is $0)."
  end

  defp format_breakdown(base_total, category_results) do
    header = "Set-Aside Breakdown (Base total: #{format_currency(base_total)})\n\n"

    sorted = Enum.sort_by(category_results, fn {_, amount} -> amount end, :desc)

    rows =
      Enum.map_join(sorted, "\n", fn {name, amount} ->
        pct = amount / base_total * 100

        "  #{name}: #{format_currency(amount)} (#{:erlang.float_to_binary(pct, decimals: 1)}%)"
      end)

    header <> rows
  end
end
