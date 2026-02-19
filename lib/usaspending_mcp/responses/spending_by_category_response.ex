defmodule UsaspendingMcp.Responses.SpendingByCategoryResponse do
  @moduledoc "Response from the spending by category endpoint"

  alias UsaspendingMcp.Responses.SpendingItem

  defstruct [:category, :results, :total, :page]

  @type t :: %__MODULE__{
          category: String.t() | nil,
          results: [SpendingItem.t()],
          total: integer(),
          page: integer()
        }

  def from_map(%{"category" => category, "results" => results} = data) do
    %__MODULE__{
      category: category,
      results: Enum.map(results, &SpendingItem.from_map/1),
      total: get_in(data, ["page_metadata", "total"]) || length(results),
      page: get_in(data, ["page_metadata", "page"]) || 1
    }
  end

  def from_map(_), do: nil
end
