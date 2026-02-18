defmodule UsaspendingMcp.Types.TASCodeObject do
  @moduledoc """
  Represents a TAS (Treasury Account Symbol) code filter for USASpending API search endpoints.

  Values are hierarchical arrays, e.g. `["091"]` or `["091", "091-0800"]`.

  ## Fields

    * `require` - (optional) TAS code paths to include
    * `exclude` - (optional) TAS code paths to exclude
  """

  defstruct [:require, :exclude]

  @type tas_path :: [String.t()]

  @type t :: %__MODULE__{
          require: [tas_path()] | nil,
          exclude: [tas_path()] | nil
        }

  @doc "Build a TASCodeObject that requires the given code paths."
  def require(paths) when is_list(paths), do: %__MODULE__{require: paths}

  @doc "Build a TASCodeObject that excludes the given code paths."
  def exclude(paths) when is_list(paths), do: %__MODULE__{exclude: paths}

  @doc "Build a TASCodeObject with both require and exclude lists."
  def new(require_paths, exclude_paths) do
    %__MODULE__{require: require_paths, exclude: exclude_paths}
  end

  @doc "Convert to a map suitable for JSON encoding in API requests."
  def to_map(%__MODULE__{} = tas) do
    %{}
    |> maybe_put(:require, tas.require)
    |> maybe_put(:exclude, tas.exclude)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
