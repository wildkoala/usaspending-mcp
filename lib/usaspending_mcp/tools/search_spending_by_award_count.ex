defmodule UsaspendingMcp.Tools.SearchSpendingByAwardCount do
  @moduledoc "Get counts of federal spending awards grouped by type (Contracts, Grants, Loans, Direct Payments, Other)"

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient

  schema do
    field :keywords, :string, description: "Search keywords"
    field :start_date, :string, description: "Start date (YYYY-MM-DD)"
    field :end_date, :string, description: "End date (YYYY-MM-DD)"
    field :agency, :string, description: "Funding agency name to filter by"
  end

  def execute(params, frame) do
    filters = build_filters(params)
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
    filters = %{}

    filters =
      case {Map.get(params, "start_date"), Map.get(params, "end_date")} do
        {nil, nil} ->
          filters

        {start_date, end_date} ->
          Map.put(filters, :time_period, [
            %{
              start_date: start_date || "2007-10-01",
              end_date: end_date || Date.to_string(Date.utc_today())
            }
          ])
      end

    filters =
      case Map.get(params, "keywords") do
        nil -> filters
        kw -> Map.put(filters, :keywords, [kw])
      end

    case Map.get(params, "agency") do
      nil ->
        filters

      agency ->
        Map.put(filters, :agencies, [
          %{type: "funding", tier: "toptier", name: agency}
        ])
    end
  end

  defp format_results(%{"results" => results}) do
    header = "Award counts by type:\n\n"

    rows =
      Enum.map_join(results, "\n", fn {type, count} ->
        "  #{type}: #{count}"
      end)

    header <> rows
  end

  defp format_results(data), do: Jason.encode!(data, pretty: true)
end
