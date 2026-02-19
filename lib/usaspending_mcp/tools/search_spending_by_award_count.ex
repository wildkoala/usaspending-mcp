defmodule UsaspendingMcp.Tools.SearchSpendingByAwardCount do
  @moduledoc "Get counts of federal spending awards grouped by type (Contracts, Grants, Loans, Direct Payments, Other)"

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient
  alias UsaspendingMcp.Responses.AwardCountResponse

  alias UsaspendingMcp.Types.{
    AdvancedFilterObject,
    AgencyObject,
    TimePeriodObject
  }

  schema do
    field :keywords, :string, description: "Search keywords"
    field :start_date, :string, description: "Start date (YYYY-MM-DD)"
    field :end_date, :string, description: "End date (YYYY-MM-DD)"
    field :agency, :string, description: "Funding agency name to filter by"

    field :set_aside_type_codes, {:list, :string},
      description:
        "Filter by set-aside type codes. HBCUs/Minority Institutions: HMT, HMP. HUBZone: HZC, HZS. Native American: BI, ISEE, ISBEE. Small Disadvantaged Business: SBP, 8AN, HS3, HS2Civ, 8A, VSBCiv, RSBCiv, SBA, ESB, 8ACCiv. Veteran Owned: SDVOSBC, SDVOSBS, VSA, VSS. Women Owned: EDWOSBSS, EDWOSB, WOSBSS, WOSB"

    field :recipient_type_names, {:list, :string},
      description:
        "Filter by recipient/business type. Categories: category_business, category_minority_owned_business, category_woman_owned_business, category_veteran_owned_business, category_special_designations, category_nonprofit, category_higher_education, category_government, category_individuals. Specific types: small_business, other_than_small_business, sole_proprietorship, 8a_program_participant, woman_owned_business, service_disabled_veteran_owned_business, nonprofit, higher_education, etc."
  end

  def execute(params, frame) do
    params = UsaspendingMcp.stringify_params(params)

    filters =
      build_filters(params)
      |> AdvancedFilterObject.to_map()

    body = %{filters: filters, subawards: false}

    case ApiClient.post("/api/v2/search/spending_by_award_count/", body) do
      {:ok, data} ->
        text = format_results(data)
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.text(text), frame}

      {:error, reason} ->
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.error(reason), frame}
    end
  end

  defp build_filters(params) do
    agencies =
      case AgencyObject.from_params(params) do
        [] -> nil
        list -> list
      end

    %AdvancedFilterObject{
      keywords: if(params["keywords"], do: [params["keywords"]]),
      time_period: build_time_period(params),
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

  defp format_results(data) do
    case AwardCountResponse.from_map(data) do
      %AwardCountResponse{counts: counts} ->
        header = "Award counts by type:\n\n"

        rows =
          Enum.map_join(counts, "\n", fn {type, count} ->
            "  #{type}: #{count}"
          end)

        header <> rows

      nil ->
        Jason.encode!(data, pretty: true)
    end
  end
end
