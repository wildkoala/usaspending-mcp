defmodule UsaspendingMcp.Tools.SearchSpendingByAward do
  @moduledoc """
  Search for individual federal spending awards (contracts, grants, loans, direct payments) from USASpending.gov.

  Returns a paginated list of awards with details including: award ID, recipient name, award amount, description, awarding agency/subagency, period of performance, NAICS/PSC codes, and internal IDs for drill-down.

  Use this tool when the user wants to find specific awards matching criteria. For aggregate counts by award type, use search_spending_by_award_count instead. For spending totals grouped by category (agency, NAICS, etc.), use spending_by_category instead.

  All filter parameters are optional. If no award_type is specified, defaults to contract types (A, B, C, D). Dates must be in YYYY-MM-DD format. The agency parameter must be the full official toptier agency name (e.g. "Department of Defense", not "DoD"). Use list_agencies first if you need to look up the exact agency name.

  Results are sorted by award amount descending. Use the page and limit parameters to paginate through large result sets.
  """

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient
  alias UsaspendingMcp.Responses.AwardSearchResponse
  alias UsaspendingMcp.Responses.AwardSearchResponse.CodeField
  import UsaspendingMcp.Formatter, only: [format_currency: 1]

  alias UsaspendingMcp.Types.{
    AdvancedFilterObject,
    AgencyObject,
    FilterObjectAwardTypes,
    NAICSCodeObject,
    PSCCodeObject,
    TimePeriodObject
  }

  schema do
    field :keywords, :string, description: "Search keywords"
    field :start_date, :string, description: "Start date (YYYY-MM-DD) for the time period filter"
    field :end_date, :string, description: "End date (YYYY-MM-DD) for the time period filter"

    field :award_type, {:list, :string},
      description:
        "Award type codes. Contracts: A, B, C, D. Grants: 02, 03, 04, 05. Loans: 07, 08. Direct payments: 06, 10. Other: 09, 11"

    field :naics_codes, {:list, :string},
      description: "NAICS codes to filter by (e.g. [\"541511\"] or prefix like [\"54\"])"

    field :psc_codes, {:list, :string},
      description: "Product/Service codes to filter by (e.g. [\"D306\", \"D399\"])"

    field :agency, :string, description: "Funding top-tier agency name to filter by"
    field :subagency, :string, description: "Funding sub-agency (subtier) name to filter by"

    field :set_aside_type_codes, {:list, :string},
      description:
        "Filter by set-aside type codes. HBCUs/Minority Institutions: HMT, HMP. HUBZone: HZC, HZS. Native American: BI, ISEE, ISBEE. Small Disadvantaged Business: SBP, 8AN, HS3, HS2Civ, 8A, VSBCiv, RSBCiv, SBA, ESB, 8ACCiv. Veteran Owned: SDVOSBC, SDVOSBS, VSA, VSS. Women Owned: EDWOSBSS, EDWOSB, WOSBSS, WOSB"

    field :recipient_type_names, {:list, :string},
      description:
        "Filter by recipient/business type. Categories: category_business, category_minority_owned_business, category_woman_owned_business, category_veteran_owned_business, category_special_designations, category_nonprofit, category_higher_education, category_government, category_individuals. Specific types: small_business, other_than_small_business, sole_proprietorship, 8a_program_participant, woman_owned_business, service_disabled_veteran_owned_business, nonprofit, higher_education, etc."

    field :page, :integer, description: "Page number (default 1)"
    field :limit, :integer, description: "Results per page (default 10, max 100)"
  end

  def execute(params, frame) do
    params = UsaspendingMcp.stringify_params(params)

    filters =
      build_filters(params)
      |> AdvancedFilterObject.to_map()

    page = Map.get(params, "page", 1)
    limit = min(Map.get(params, "limit", 10), 100)

    award_types = Map.get(params, "award_type", FilterObjectAwardTypes.contracts())

    fields =
      case categorize_award_types(award_types) do
        :contracts -> contract_fields()
        :assistance -> assistance_fields()
        :mixed -> (contract_fields() ++ assistance_fields()) |> Enum.uniq()
      end

    body = %{
      filters: filters,
      fields: fields,
      page: page,
      limit: limit,
      sort: "Award Amount",
      order: "desc",
      subawards: false
    }

    case ApiClient.post("/api/v2/search/spending_by_award/", body) do
      {:ok, data} ->
        text = format_results(data)
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.text(text), frame}

      {:error, reason} ->
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.error(reason), frame}
    end
  end

  defp build_filters(params) do
    award_types = Map.get(params, "award_type", FilterObjectAwardTypes.contracts())

    agencies =
      case AgencyObject.from_params(params) do
        [] -> nil
        list -> list
      end

    psc_codes =
      case params["psc_codes"] do
        nil -> nil
        codes -> PSCCodeObject.require(Enum.map(codes, &[&1]))
      end

    %AdvancedFilterObject{
      keywords: if(params["keywords"], do: [params["keywords"]]),
      time_period: build_time_period(params),
      award_type_codes: award_types,
      naics_codes: if(params["naics_codes"], do: NAICSCodeObject.require(params["naics_codes"])),
      psc_codes: psc_codes,
      agencies: agencies,
      set_aside_type_codes: params["set_aside_type_codes"],
      recipient_type_names: params["recipient_type_names"]
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

  defp categorize_award_types(types) do
    contract_codes = MapSet.new(FilterObjectAwardTypes.all_contracts())

    has_contracts = Enum.any?(types, &MapSet.member?(contract_codes, &1))
    has_assistance = Enum.any?(types, &(not MapSet.member?(contract_codes, &1)))

    cond do
      has_contracts and has_assistance -> :mixed
      has_contracts -> :contracts
      true -> :assistance
    end
  end

  defp contract_fields do
    [
      "Award ID", "Recipient Name", "Award Amount", "Total Outlays",
      "Description", "Start Date", "End Date", "Awarding Agency",
      "Awarding Sub Agency", "Contract Award Type",
      "NAICS", "PSC",
      "recipient_id", "generated_internal_id"
    ]
  end

  defp assistance_fields do
    [
      "Award ID", "Recipient Name", "Award Amount", "Total Outlays",
      "Description", "Start Date", "End Date", "Awarding Agency",
      "Awarding Sub Agency", "Award Type", "CFDA Number",
      "recipient_id", "generated_internal_id"
    ]
  end

  defp format_results(data) do
    case AwardSearchResponse.from_map(data) do
      %AwardSearchResponse{results: results, total: total, page: page} ->
        header = "Found #{total} awards (page #{page}):\n\n"

        rows =
          Enum.map_join(results, "\n---\n", fn award ->
            naics_line = format_code_field("NAICS", award.naics)
            psc_line = format_code_field("PSC", award.psc)
            cfda_line = if award.cfda_number, do: "\n  CFDA: #{award.cfda_number}", else: ""

            """
            Award ID: #{award.award_id || "N/A"}
            Recipient: #{award.recipient_name || "N/A"}
            Amount: #{format_currency(award.award_amount)}
            Description: #{award.description || "N/A"}
            Agency: #{award.awarding_agency || "N/A"} / #{award.awarding_sub_agency || "N/A"}
            Period: #{award.start_date || "?"} to #{award.end_date || "?"}#{naics_line}#{psc_line}#{cfda_line}
            ID: #{award.generated_internal_id || "N/A"}\
            """
          end)

        header <> rows

      nil ->
        Jason.encode!(data, pretty: true)
    end
  end

  defp format_code_field(_label, nil), do: ""
  defp format_code_field(label, %CodeField{code: code, description: desc}) when not is_nil(desc), do: "\n  #{label}: #{code} - #{desc}"
  defp format_code_field(label, %CodeField{code: code}), do: "\n  #{label}: #{code}"
end
