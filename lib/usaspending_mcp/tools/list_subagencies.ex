defmodule UsaspendingMcp.Tools.ListSubagencies do
  @moduledoc """
  List sub-agencies (subtier agencies and offices) under a specific top-tier federal agency, with obligation amounts and award counts.

  The 'toptier_code' parameter is REQUIRED — this is the 3-4 digit CGAC or FREC code for the agency. Use list_agencies first to find the correct toptier code for an agency.

  Returns sub-agency name, abbreviation, total obligations, transaction count, new award count, and child offices. Use this to drill down into an agency's organizational structure and spending distribution.

  Optional filters include fiscal_year, award_type_codes, and agency_type (awarding vs funding perspective).
  """

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient
  alias UsaspendingMcp.Responses.SubagencyListResponse
  alias UsaspendingMcp.Responses.SubagencyListResponse.Office
  import UsaspendingMcp.Formatter, only: [format_currency: 1]

  schema do
    field :toptier_code, {:required, :string},
      description:
        "The 3-4 digit toptier agency code (CGAC or FREC). Use list_agencies to find this code."

    field :fiscal_year, :integer, description: "Fiscal year to query (default: current FY)"

    field :award_type_codes, {:list, :string},
      description:
        "Filter by award type codes. Contracts: A, B, C, D. Grants: 02, 03, 04, 05. Loans: 07, 08. Direct payments: 06, 10. Other: 09, 11"

    field :agency_type, :string,
      description: "Perspective: awarding or funding (default: awarding)"

    field :sort, :string,
      description:
        "Sort by: name, total_obligations, transaction_count, or new_award_count (default: total_obligations)"

    field :order, :string, description: "Sort order: asc or desc (default: desc)"
    field :page, :integer, description: "Page number (default: 1)"
    field :limit, :integer, description: "Results per page (default: 10)"
  end

  def execute(params, frame) do
    params = UsaspendingMcp.stringify_params(params)
    toptier_code = Map.fetch!(params, "toptier_code")

    query_params =
      []
      |> maybe_add(:fiscal_year, Map.get(params, "fiscal_year"))
      |> maybe_add(:award_type_codes, Map.get(params, "award_type_codes"))
      |> maybe_add(:agency_type, Map.get(params, "agency_type"))
      |> maybe_add(:sort, Map.get(params, "sort"))
      |> maybe_add(:order, Map.get(params, "order"))
      |> maybe_add(:page, Map.get(params, "page"))
      |> maybe_add(:limit, Map.get(params, "limit"))

    case ApiClient.get("/api/v2/agency/#{toptier_code}/sub_agency/", query_params) do
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
    case SubagencyListResponse.from_map(data) do
      %SubagencyListResponse{toptier_code: code, fiscal_year: fy, results: results, total: total, page: page} ->
        header = "Sub-agencies for toptier code #{code}, FY #{fy} (#{total} total, page #{page}):\n\n"

        rows =
          Enum.map_join(results, "\n---\n", fn sub ->
            children_text = format_children(sub.children)

            """
            #{sub.name}#{if sub.abbreviation, do: " (#{sub.abbreviation})", else: ""}
              Total Obligations: #{format_currency(sub.total_obligations)}
              Transactions: #{sub.transaction_count || "N/A"}
              New Awards: #{sub.new_award_count || "N/A"}#{children_text}\
            """
          end)

        header <> rows

      nil ->
        Jason.encode!(data, pretty: true)
    end
  end

  defp format_children([]), do: ""

  defp format_children(children) do
    entries =
      Enum.map_join(children, "\n", fn %Office{name: name, code: code, total_obligations: obligations} ->
        "    - #{name} (#{code}): #{format_currency(obligations)}"
      end)

    "\n  Offices:\n" <> entries
  end
end
