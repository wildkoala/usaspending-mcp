defmodule UsaspendingMcp.Types.NAICSCodeObject do
  @moduledoc """
  Represents a NAICS code filter for USASpending API search endpoints.

  ## Fields

    * `require` - (optional) NAICS codes to include (e.g. `["541511"]` or prefix `["54"]`)
    * `exclude` - (optional) NAICS codes to exclude
  """

  defstruct [:require, :exclude]

  @type t :: %__MODULE__{
          require: [String.t()] | nil,
          exclude: [String.t()] | nil
        }

  @doc "Build a NAICSCodeObject that requires the given codes."
  def require(codes) when is_list(codes), do: %__MODULE__{require: codes}

  @doc "Build a NAICSCodeObject that excludes the given codes."
  def exclude(codes) when is_list(codes), do: %__MODULE__{exclude: codes}

  @doc "Build a NAICSCodeObject with both require and exclude lists."
  def new(require_codes, exclude_codes) do
    %__MODULE__{require: require_codes, exclude: exclude_codes}
  end

  @doc "Convert to a map suitable for JSON encoding in API requests."
  def to_map(%__MODULE__{} = naics) do
    %{}
    |> maybe_put(:require, naics.require)
    |> maybe_put(:exclude, naics.exclude)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
