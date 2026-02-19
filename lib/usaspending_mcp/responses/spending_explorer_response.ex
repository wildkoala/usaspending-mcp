defmodule UsaspendingMcp.Responses.SpendingExplorerResponse do
  @moduledoc "Response from the spending explorer endpoint"

  alias UsaspendingMcp.Responses.SpendingItem

  defstruct [:results, :total]

  @type t :: %__MODULE__{
          results: [SpendingItem.t()],
          total: number() | nil
        }

  def from_map(%{"results" => results, "total" => total}) do
    %__MODULE__{
      results: Enum.map(results, &SpendingItem.from_map/1),
      total: total
    }
  end

  def from_map(_), do: nil
end
