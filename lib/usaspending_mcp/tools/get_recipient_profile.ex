defmodule UsaspendingMcp.Tools.GetRecipientProfile do
  @moduledoc """
  Get profile information for a specific federal spending recipient, including location, business types, and spending breakdown by award type.

  The 'recipient_id' parameter is REQUIRED — this must be a valid recipient hash ID in UUID format. These IDs are returned by search_spending_by_award and get_award_details. You must search for awards first to obtain a valid recipient_id.

  Returns recipient name, DUNS, UEI, parent organization, location, business type classifications, total transaction amount, total award count, and a breakdown of spending by award type (contracts, grants, loans, direct payments, other).

  The optional 'year' parameter filters to a specific fiscal year. Use "all" for all years or "latest" (the default) for the most recent year.
  """

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient
  alias UsaspendingMcp.Responses.RecipientProfileResponse
  import UsaspendingMcp.Formatter, only: [format_currency: 1, format_detailed_location: 1, format_list: 1]

  schema do
    field :recipient_id, {:required, :string},
      description: "The recipient hash ID (UUID format, obtained from award search results)"

    field :year, :string,
      description: "Fiscal year to filter by, or 'all' for all years, or 'latest' (default: latest)"
  end

  def execute(params, frame) do
    params = UsaspendingMcp.stringify_params(params)
    recipient_id = params["recipient_id"]
    year = Map.get(params, "year", "latest")

    case ApiClient.get("/api/v2/recipient/#{URI.encode(recipient_id)}/", year: year) do
      {:ok, data} ->
        text = format_result(RecipientProfileResponse.from_map(data))
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.text(text), frame}

      {:error, reason} ->
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.error(reason), frame}
    end
  end

  defp format_result(%RecipientProfileResponse{} = r) do
    amounts = r.amounts_by_type

    """
    Recipient Profile
    =================
    Name: #{r.name || "N/A"}
    DUNS: #{r.duns || "N/A"}
    UEI: #{r.uei || "N/A"}
    Recipient ID: #{r.recipient_id || "N/A"}
    Parent: #{r.parent_name || "N/A"}

    Location: #{format_detailed_location(r.location)}

    Business Types: #{format_list(r.business_types)}

    Total Transaction Amount: #{format_currency(r.total_transaction_amount)}
    Total Awards: #{r.total_awards || "N/A"}

    By Award Type:
      Contracts: #{format_currency(amounts.contracts)}
      Grants: #{format_currency(amounts.grants)}
      Loans: #{format_currency(amounts.loans)}
      Direct Payments: #{format_currency(amounts.direct_payments)}
      Other: #{format_currency(amounts.other)}\
    """
  end
end
