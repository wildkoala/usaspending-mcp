defmodule UsaspendingMcp.Tools.GetAwardDetails do
  @moduledoc "Get detailed information about a specific federal spending award by its ID"

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient

  schema do
    field :award_id, {:required, :string},
      description:
        "The internal award ID (generated_unique_award_id) or the award's internal database ID number"
  end

  def execute(params, frame) do
    params = UsaspendingMcp.stringify_params(params)
    award_id = params["award_id"]

    case ApiClient.get("/api/v2/awards/#{URI.encode(award_id)}/") do
      {:ok, data} ->
        text = format_result(data)
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.text(text), frame}

      {:error, reason} ->
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.error(reason), frame}
    end
  end

  defp format_result(data) do
    recipient = data["recipient"] || %{}
    place = data["place_of_performance"] || %{}
    period = data["period_of_performance"] || %{}
    agency = data["funding_agency"] || %{}
    agency_detail = agency["toptier_agency"] || %{}

    """
    Award Details
    =============
    Award ID: #{data["generated_unique_award_id"] || "N/A"}
    Type: #{data["type_description"] || data["type"] || "N/A"}
    Category: #{data["category"] || "N/A"}
    Description: #{data["description"] || "N/A"}

    Amounts:
      Total Obligation: #{format_currency(data["total_obligation"])}
      Base and All Options: #{format_currency(data["base_and_all_options_value"])}
      Total Outlays: #{format_currency(data["total_outlays"])}

    Recipient:
      Name: #{recipient["recipient_name"] || "N/A"}
      ID: #{recipient["recipient_hash"] || "N/A"}
      Location: #{format_location(recipient["location"])}

    Funding Agency: #{agency_detail["name"] || "N/A"}

    Place of Performance: #{format_location(place)}

    Period of Performance:
      Start: #{period["start_date"] || "N/A"}
      End: #{period["end_date"] || "N/A"}

    NAICS: #{data["naics_description"] || "N/A"}
    PSC: #{data["psc_description"] || "N/A"}
    CFDA: #{format_cfda(data["cfda_info"])}\
    """
  end

  defp format_location(nil), do: "N/A"

  defp format_location(loc) when is_map(loc) do
    parts =
      [loc["city_name"], loc["state_code"] || loc["state_name"], loc["country_name"]]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(", ")

    if parts == "", do: "N/A", else: parts
  end

  defp format_location(_), do: "N/A"

  defp format_cfda(nil), do: "N/A"
  defp format_cfda([]), do: "N/A"

  defp format_cfda(cfda_list) when is_list(cfda_list) do
    Enum.map_join(cfda_list, "; ", fn cfda ->
      "#{cfda["cfda_number"]} - #{cfda["cfda_title"]}"
    end)
  end

  defp format_cfda(_), do: "N/A"

  defp format_currency(nil), do: "N/A"

  defp format_currency(amount) when is_number(amount),
    do: "$#{:erlang.float_to_binary(amount / 1, decimals: 2)}"

  defp format_currency(amount), do: "$#{amount}"
end
