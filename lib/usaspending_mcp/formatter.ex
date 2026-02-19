defmodule UsaspendingMcp.Formatter do
  @moduledoc "Shared formatting helpers for tool output"

  def format_currency(nil), do: "N/A"

  def format_currency(amount) when is_number(amount),
    do: "$#{:erlang.float_to_binary(amount / 1, decimals: 2)}"

  def format_currency(amount), do: "$#{amount}"

  def format_location(nil), do: "N/A"

  def format_location(loc) when is_map(loc) do
    parts =
      [loc["city_name"], loc["state_code"] || loc["state_name"], loc["country_name"]]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(", ")

    if parts == "", do: "N/A", else: parts
  end

  def format_location(_), do: "N/A"

  def format_detailed_location(loc) when map_size(loc) == 0, do: "N/A"

  def format_detailed_location(loc) when is_map(loc) do
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

  def format_detailed_location(_), do: "N/A"

  def format_list(nil), do: "N/A"
  def format_list([]), do: "None"
  def format_list(items) when is_list(items), do: Enum.join(items, ", ")
  def format_list(_), do: "N/A"
end
