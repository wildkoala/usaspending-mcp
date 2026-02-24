defmodule UsaspendingMcp.Tools.ListAgencies do
  @moduledoc """
  List all top-tier federal agencies with their budget authority, obligated amounts, and outlays for the current fiscal year.

  Returns agency name, budget authority amount, obligated amount, outlay amount, percentage of total budget authority, and active fiscal year. No parameters are required — call with no arguments to get all agencies.

  Use this tool to look up exact agency names and codes before using them as filters in other tools. Many other tools require the exact official agency name (e.g. "Department of Defense", "Department of Health and Human Services").

  Optional sort and order parameters control the output ordering. Defaults to sorting by budget_authority_amount descending.
  """

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient
  alias UsaspendingMcp.Responses.AgencyListResponse
  import UsaspendingMcp.Formatter, only: [format_currency: 1]

  schema do
    field :sort, :string,
      description:
        "Field to sort by: agency_name, active_fy, outlay_amount, obligated_amount, budget_authority_amount, current_total_budget_authority_amount, or percentage_of_total_budget_authority (default: budget_authority_amount)"

    field :order, :string, description: "Sort order: asc or desc (default: desc)"
  end

  def execute(params, frame) do
    params = UsaspendingMcp.stringify_params(params)
    query_params =
      []
      |> maybe_add(:sort, Map.get(params, "sort"))
      |> maybe_add(:order, Map.get(params, "order"))

    case ApiClient.get("/api/v2/references/toptier_agencies/", query_params) do
      {:ok, data} ->
        text = format_results(data)
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.text(text), frame}

      {:error, reason} ->
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.error(reason), frame}
    end
  end

  defp maybe_add(params, _key, nil), do: params
  defp maybe_add(params, key, value), do: [{key, value} | params]

  defp format_results(data) do
    case AgencyListResponse.from_map(data) do
      %AgencyListResponse{agencies: agencies} ->
        header = "Top-tier Federal Agencies (#{length(agencies)} total):\n\n"

        rows =
          Enum.map_join(agencies, "\n---\n", fn agency ->
            """
            #{agency.agency_name}
              Budget Authority: #{format_currency(agency.budget_authority_amount)}
              Obligated: #{format_currency(agency.obligated_amount)}
              Outlays: #{format_currency(agency.outlay_amount)}
              % of Total Budget: #{agency.percentage_of_total_budget_authority || "N/A"}%
              FY: #{agency.active_fy || "N/A"}\
            """
          end)

        header <> rows

      nil ->
        Jason.encode!(data, pretty: true)
    end
  end
end
