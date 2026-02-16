defmodule UsaspendingMcp.Tools.GetRecipientProfile do
  @moduledoc "Get profile information for a federal spending recipient including location, business type, and spending breakdown"

  use Hermes.Server.Component, type: :tool

  alias UsaspendingMcp.ApiClient

  schema do
    field :recipient_id, {:required, :string},
      description: "The recipient hash ID (UUID format, obtained from award search results)"

    field :year, :string,
      description: "Fiscal year to filter by, or 'all' for all years, or 'latest' (default: latest)"
  end

  def execute(params, frame) do
    recipient_id = params["recipient_id"]
    year = Map.get(params, "year", "latest")

    case ApiClient.get("/api/v2/recipient/#{URI.encode(recipient_id)}/", year: year) do
      {:ok, data} ->
        text = format_result(data)
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.text(text), frame}

      {:error, reason} ->
        {:reply, Hermes.Server.Response.tool() |> Hermes.Server.Response.error(reason), frame}
    end
  end

  defp format_result(data) do
    location = data["location"] || %{}

    """
    Recipient Profile
    =================
    Name: #{data["name"] || "N/A"}
    DUNS: #{data["duns"] || "N/A"}
    UEI: #{data["uei"] || "N/A"}
    Recipient ID: #{data["recipient_id"] || "N/A"}
    Parent: #{data["parent_name"] || "N/A"}

    Location: #{format_location(location)}

    Business Types: #{format_list(data["business_types"])}

    Total Transaction Amount: #{format_currency(data["total_transaction_amount"])}
    Total Awards: #{data["total_awards"] || "N/A"}

    By Award Type:
      Contracts: #{format_currency(get_in(data, ["total_amounts_by_award_type", "contracts"]))}
      Grants: #{format_currency(get_in(data, ["total_amounts_by_award_type", "grants"]))}
      Loans: #{format_currency(get_in(data, ["total_amounts_by_award_type", "loans"]))}
      Direct Payments: #{format_currency(get_in(data, ["total_amounts_by_award_type", "direct_payments"]))}
      Other: #{format_currency(get_in(data, ["total_amounts_by_award_type", "other"]))}\
    """
  end

  defp format_location(loc) when map_size(loc) == 0, do: "N/A"

  defp format_location(loc) do
    parts =
      [
        loc["address_line1"],
        loc["city_name"],
        loc["state_code"],
        loc["zip5"] || loc["zip"],
        loc["country_name"]
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(", ")

    if parts == "", do: "N/A", else: parts
  end

  defp format_list(nil), do: "N/A"
  defp format_list([]), do: "None"
  defp format_list(items) when is_list(items), do: Enum.join(items, ", ")
  defp format_list(_), do: "N/A"

  defp format_currency(nil), do: "N/A"

  defp format_currency(amount) when is_number(amount),
    do: "$#{:erlang.float_to_binary(amount / 1, decimals: 2)}"

  defp format_currency(amount), do: "$#{amount}"
end
