defmodule UsaspendingMcp.Tools.ExtentCompetedBreakdown do
  @moduledoc "Calculate what percentage of spending goes to each extent-competed category (e.g. full and open competition, not competed, competed under SAP) for given filters. Returns a complete breakdown in a single call — no follow-up tool calls needed."

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient

  alias UsaspendingMcp.Types.{
    AdvancedFilterObject,
    AgencyObject,
    NAICSCodeObject,
    TimePeriodObject
  }

  import UsaspendingMcp.Formatter, only: [format_currency: 1]

  @extent_competed_categories [
    {"Competed Under SAP", ["F"]},
    {"Competed Delivery Order", ["CDOCiv"]},
    {"Follow-on to Competed Action", ["E Civ"]},
    {"Full and Open Competition", ["A"]},
    {"Full and Open After Exclusion of Sources", ["D"]},
    {"Non-competitive Delivery Order", ["NDOCiv"]},
    {"Not Available for Competition", ["B"]},
    {"Not Competed", ["C"]},
    {"Not Competed Under SAP", ["G"]}
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

    queries =
      [{:base, nil} | Enum.map(@extent_competed_categories, fn {name, codes} -> {name, codes} end)]

    results =
      Task.async_stream(
        queries,
        fn {label, codes} ->
          filter =
            if codes do
              %{base_filter | extent_competed_type_codes: codes}
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
        max_concurrency: 10,
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
      "Extent-competed breakdown could not be calculated (base total is $0)."
  end

  defp format_breakdown(base_total, category_results) do
    header = "Extent Competed Breakdown (Base total: #{format_currency(base_total)})\n\n"

    sorted = Enum.sort_by(category_results, fn {_, amount} -> amount end, :desc)

    rows =
      Enum.map_join(sorted, "\n", fn {name, amount} ->
        pct = amount / base_total * 100

        "  #{name}: #{format_currency(amount)} (#{:erlang.float_to_binary(pct, decimals: 1)}%)"
      end)

    header <> rows
  end
end
