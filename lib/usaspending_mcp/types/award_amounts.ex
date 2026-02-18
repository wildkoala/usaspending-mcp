defmodule UsaspendingMcp.Types.AwardAmounts do
  @moduledoc """
  Represents an award amount range filter for USASpending API search endpoints.

  ## Fields

    * `lower_bound` - (optional) minimum award amount
    * `upper_bound` - (optional) maximum award amount
  """

  defstruct [:lower_bound, :upper_bound]

  @type t :: %__MODULE__{
          lower_bound: number() | nil,
          upper_bound: number() | nil
        }

  @doc "Build an AwardAmounts filter with both bounds."
  def between(lower, upper), do: %__MODULE__{lower_bound: lower, upper_bound: upper}

  @doc "Build an AwardAmounts filter with only a minimum."
  def at_least(lower), do: %__MODULE__{lower_bound: lower}

  @doc "Build an AwardAmounts filter with only a maximum."
  def at_most(upper), do: %__MODULE__{upper_bound: upper}

  @doc "Convert to a map suitable for JSON encoding in API requests."
  def to_map(%__MODULE__{} = amounts) do
    %{}
    |> maybe_put(:lower_bound, amounts.lower_bound)
    |> maybe_put(:upper_bound, amounts.upper_bound)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
