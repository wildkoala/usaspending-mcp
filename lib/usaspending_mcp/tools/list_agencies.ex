defmodule UsaspendingMcp.Tools.ListAgencies do
  @moduledoc "List top-tier federal agencies with budget authority, obligated amounts, and outlays"

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient

  schema do
    field :sort, :string,
      description:
        "Field to sort by: agency_name, active_fy, outlay_amount, obligated_amount, budget_authority_amount, current_total_budget_authority_amount, or percentage_of_total_budget_authority (default: budget_authority_amount)"

    field :order, :string, description: "Sort order: asc or desc (default: desc)"
  end

  def execute(params, frame) do
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

  defp format_results(%{"results" => results}) do
    header = "Top-tier Federal Agencies (#{length(results)} total):\n\n"

    rows =
      Enum.map_join(results, "\n---\n", fn agency ->
        """
        #{agency["agency_name"]}
          Budget Authority: #{format_currency(agency["budget_authority_amount"])}
          Obligated: #{format_currency(agency["obligated_amount"])}
          Outlays: #{format_currency(agency["outlay_amount"])}
          % of Total Budget: #{agency["percentage_of_total_budget_authority"] || "N/A"}%
          FY: #{agency["active_fy"] || "N/A"}\
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
