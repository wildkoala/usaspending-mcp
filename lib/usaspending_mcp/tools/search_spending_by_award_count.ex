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
      agencies: agencies
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
