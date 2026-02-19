defmodule UsaspendingMcp.Responses.SpendingItem do
  @moduledoc "A single spending result item with name, code, and amount"

  defstruct [:name, :code, :amount]

  @type t :: %__MODULE__{
          name: String.t() | nil,
          code: String.t() | nil,
          amount: number() | nil
        }

  def from_map(map) when is_map(map) do
    %__MODULE__{
      name: map["name"],
      code: map["code"],
      amount: map["amount"]
    }
  end
end
