defmodule UsaspendingMcp.Tools.SpendingByCategory do
  @moduledoc """
  Find which entities (agencies, NAICS codes, recipients, etc.) have the most spending for given filters. Groups and ranks spending by a chosen category dimension.

  The 'category' parameter is REQUIRED and determines how results are grouped. Valid values: awarding_agency, awarding_subagency, funding_agency, funding_subagency, naics, psc, recipient_duns, cfda, country, state_territory, county, district, federal_account.

  Returns a ranked list of entities in that category with their total spending amounts. For example, category="awarding_agency" with naics_codes=["541511"] shows which agencies spend the most on custom software development.

  All filter parameters except category are optional. Dates must be in YYYY-MM-DD format. The agency parameter must be the full official toptier agency name. Use list_agencies to look up exact names. Do not set set_aside_type_codes unless the user explicitly asks about set-asides. Do not set recipient_type_names unless the user explicitly asks about recipient/business types.

  For a complete set-aside percentage breakdown, use set_aside_breakdown instead. For extent-competed analysis, use extent_competed_breakdown instead.
  """

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient
  alias UsaspendingMcp.Responses.SpendingByCategoryResponse
  import UsaspendingMcp.Formatter, only: [format_currency: 1]

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

    field :set_aside_type_codes, {:list, :string},
      description:
        "Filter by set-aside type codes. Only set this is the user explicit mentions set-asides. HBCUs/Minority Institutions: HMT, HMP. HUBZone: HZC, HZS. Native American: BI, ISEE, ISBEE. Small Disadvantaged Business: SBP, 8AN, HS3, HS2Civ, 8A, VSBCiv, RSBCiv, SBA, ESB, 8ACCiv. Veteran Owned: SDVOSBC, SDVOSBS, VSA, VSS. Women Owned: EDWOSBSS, EDWOSB, WOSBSS, WOSB"

    field :recipient_type_names, {:list, :string},
      description:
        "Filter by recipient/business type. Only set this if the user explicitly mentions recipient. Categories: category_business, category_minority_owned_business, category_woman_owned_business, category_veteran_owned_business, category_special_designations, category_nonprofit, category_higher_education, category_government, category_individuals. Specific types: small_business, other_than_small_business, sole_proprietorship, 8a_program_participant, woman_owned_business, service_disabled_veteran_owned_business, nonprofit, higher_education, etc."

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
      psc_codes: params["psc_codes"],
      set_aside_type_codes: params["set_aside_type_codes"],
      recipient_type_names: params["recipient_type_names"]
    }
  end

  defp build_time_period(params) do
    case {params["start_date"], params["end_date"]} do
      {nil, nil} ->
        nil

      {start_date, end_date} ->
        default_start =
          Date.utc_today() |> Date.add(-4 * 365) |> Date.to_string()

        [
          TimePeriodObject.new(
            start_date || default_start,
            end_date || Date.to_string(Date.utc_today())
          )
        ]
    end
  end

  defp format_results(data) do
    case SpendingByCategoryResponse.from_map(data) do
      %SpendingByCategoryResponse{category: category, results: results, total: total, page: page} ->
        header = "Spending by #{category} (#{total} results, page #{page}):\n\n"

        rows =
          Enum.map_join(results, "\n---\n", fn item ->
            """
            #{item.name || "Unknown"}#{if item.code, do: " (#{item.code})", else: ""}
              Amount: #{format_currency(item.amount)}
            """
          end)

        header <> rows

      nil ->
        Jason.encode!(data, pretty: true)
    end
  end
end
