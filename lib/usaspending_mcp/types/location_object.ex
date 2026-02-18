defmodule UsaspendingMcp.Types.LocationObject do
  @moduledoc """
  Represents a location filter for USASpending API search endpoints.

  ## Fields

    * `country` - (optional) country code
    * `state` - (optional) state code
    * `county` - (optional) county code
    * `congressional_code` - (optional) congressional district code
  """

  defstruct [:country, :state, :county, :congressional_code]

  @type t :: %__MODULE__{
          country: String.t() | nil,
          state: String.t() | nil,
          county: String.t() | nil,
          congressional_code: String.t() | nil
        }

  @doc "Build a LocationObject from keyword options."
  def new(opts \\ []) do
    %__MODULE__{
      country: Keyword.get(opts, :country),
      state: Keyword.get(opts, :state),
      county: Keyword.get(opts, :county),
      congressional_code: Keyword.get(opts, :congressional_code)
    }
  end

  @doc "Convert to a map suitable for JSON encoding in API requests."
  def to_map(%__MODULE__{} = loc) do
    %{}
    |> maybe_put(:country, loc.country)
    |> maybe_put(:state, loc.state)
    |> maybe_put(:county, loc.county)
    |> maybe_put(:congressional_code, loc.congressional_code)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
