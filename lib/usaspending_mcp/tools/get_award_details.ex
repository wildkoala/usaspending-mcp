defmodule UsaspendingMcp.Tools.GetAwardDetails do
  @moduledoc """
  Get comprehensive details about a single federal spending award by its unique ID.

  The 'award_id' parameter is REQUIRED — this must be either the generated_unique_award_id or the internal database ID number. These IDs are returned by search_spending_by_award in the "ID" field (generated_internal_id). You must search for awards first to obtain a valid award_id.

  Returns full award details including: award type, description, total obligation, base and all options value, total outlays, recipient name and ID, funding agency, place of performance, period of performance dates, NAICS code, PSC code, and CFDA information.

  Use the returned recipient ID (hash) with get_recipient_profile to get more information about the award recipient.
  """

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient
  alias UsaspendingMcp.Responses.AwardDetailResponse
  alias UsaspendingMcp.Responses.AwardDetailResponse.{Recipient, CfdaInfo}
  import UsaspendingMcp.Formatter, only: [format_currency: 1, format_location: 1]

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
        text = format_result(AwardDetailResponse.from_map(data))
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.text(text), frame}

      {:error, reason} ->
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.error(reason), frame}
    end
  end

  defp format_result(%AwardDetailResponse{} = award) do
    %Recipient{name: recipient_name, hash: recipient_hash, location: recipient_location} =
      award.recipient

    """
    Award Details
    =============
    Award ID: #{award.award_id || "N/A"}
    Type: #{award.type_description || award.type || "N/A"}
    Category: #{award.category || "N/A"}
    Description: #{award.description || "N/A"}

    Amounts:
      Total Obligation: #{format_currency(award.total_obligation)}
      Base and All Options: #{format_currency(award.base_and_all_options_value)}
      Total Outlays: #{format_currency(award.total_outlays)}

    Recipient:
      Name: #{recipient_name || "N/A"}
      ID: #{recipient_hash || "N/A"}
      Location: #{format_location(recipient_location)}

    Funding Agency: #{award.funding_agency_name || "N/A"}

    Place of Performance: #{format_location(award.place_of_performance)}

    Period of Performance:
      Start: #{award.start_date || "N/A"}
      End: #{award.end_date || "N/A"}

    NAICS: #{award.naics_description || "N/A"}
    PSC: #{award.psc_description || "N/A"}
    CFDA: #{format_cfda(award.cfda_info)}\
    """
  end

  defp format_cfda([]), do: "N/A"

  defp format_cfda(cfda_list) when is_list(cfda_list) do
    Enum.map_join(cfda_list, "; ", fn %CfdaInfo{number: number, title: title} ->
      "#{number} - #{title}"
    end)
  end
end
