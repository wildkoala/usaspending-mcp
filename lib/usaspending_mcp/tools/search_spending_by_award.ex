defmodule UsaspendingMcp.Tools.SearchSpendingByAward do
  @moduledoc "Search for federal spending awards with various filters including keywords, time periods, award types, and agencies"

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient

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

  defp format_results(%{"results" => results, "page_metadata" => meta}) do
    total = meta["total"] || 0
    page = meta["page"] || 1

    header = "Found #{total} awards (page #{page}):\n\n"

    rows =
      Enum.map_join(results, "\n---\n", fn award ->
        naics_line = format_code_field("NAICS", award["NAICS"])
        psc_line = format_code_field("PSC", award["PSC"])
        cfda_line = if award["CFDA Number"], do: "\n  CFDA: #{award["CFDA Number"]}", else: ""

        """
        Award ID: #{award["Award ID"] || "N/A"}
        Recipient: #{award["Recipient Name"] || "N/A"}
        Amount: #{format_currency(award["Award Amount"])}
        Description: #{award["Description"] || "N/A"}
        Agency: #{award["Awarding Agency"] || "N/A"} / #{award["Awarding Sub Agency"] || "N/A"}
        Period: #{award["Start Date"] || "?"} to #{award["End Date"] || "?"}#{naics_line}#{psc_line}#{cfda_line}
        ID: #{award["generated_internal_id"] || "N/A"}\
        """
      end)

    header <> rows
  end

  defp format_results(data), do: Jason.encode!(data, pretty: true)

  defp format_code_field(_label, nil), do: ""
  defp format_code_field(label, %{"code" => code, "description" => desc}), do: "\n  #{label}: #{code} - #{desc}"
  defp format_code_field(label, %{"code" => code}), do: "\n  #{label}: #{code}"
  defp format_code_field(label, value) when is_binary(value), do: "\n  #{label}: #{value}"

  defp format_currency(nil), do: "N/A"

  defp format_currency(amount) when is_number(amount),
    do: "$#{:erlang.float_to_binary(amount / 1, decimals: 2)}"

  defp format_currency(amount), do: "$#{amount}"
end
