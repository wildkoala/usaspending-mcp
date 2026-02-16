defmodule UsaspendingMcp.Tools.SearchSpendingByAward do
  @moduledoc "Search for federal spending awards with various filters including keywords, time periods, award types, and agencies"

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient

  schema do
    field :keywords, :string, description: "Search keywords"
    field :start_date, :string, description: "Start date (YYYY-MM-DD) for the time period filter"
    field :end_date, :string, description: "End date (YYYY-MM-DD) for the time period filter"

    field :award_type, {:list, :string},
      description:
        "Award type codes. Contracts: A, B, C, D. Grants: 02, 03, 04, 05. Loans: 07, 08. Direct payments: 06, 10. Other: 09, 11"

    field :agency, :string, description: "Funding agency name to filter by"
    field :page, :integer, description: "Page number (default 1)"
    field :limit, :integer, description: "Results per page (default 10, max 100)"
  end

  def execute(params, frame) do
    filters = build_filters(params)
    page = Map.get(params, "page", 1)
    limit = min(Map.get(params, "limit", 10), 100)

    award_types = Map.get(params, "award_type", ["A", "B", "C", "D"])

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

    filters =
      case Map.get(params, "award_type") do
        nil -> Map.put(filters, :award_type_codes, ["A", "B", "C", "D"])
        types -> Map.put(filters, :award_type_codes, types)
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

  defp categorize_award_types(types) do
    contract_codes =
      MapSet.new([
        "A", "B", "C", "D",
        "IDV_A", "IDV_B", "IDV_B_A", "IDV_B_B", "IDV_B_C", "IDV_C", "IDV_D", "IDV_E"
      ])

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
      "Awarding Sub Agency", "Contract Award Type", "recipient_id", "internal_id"
    ]
  end

  defp assistance_fields do
    [
      "Award ID", "Recipient Name", "Award Amount", "Total Outlays",
      "Description", "Start Date", "End Date", "Awarding Agency",
      "Awarding Sub Agency", "Award Type", "recipient_id", "internal_id"
    ]
  end

  defp format_results(%{"results" => results, "page_metadata" => meta}) do
    total = meta["total"] || 0
    page = meta["page"] || 1

    header = "Found #{total} awards (page #{page}):\n\n"

    rows =
      Enum.map_join(results, "\n---\n", fn award ->
        """
        Award ID: #{award["Award ID"] || "N/A"}
        Recipient: #{award["Recipient Name"] || "N/A"}
        Amount: #{format_currency(award["Award Amount"])}
        Description: #{award["Description"] || "N/A"}
        Agency: #{award["Awarding Agency"] || "N/A"}
        Period: #{award["Start Date"] || "?"} to #{award["End Date"] || "?"}
        Internal ID: #{award["internal_id"] || "N/A"}\
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
