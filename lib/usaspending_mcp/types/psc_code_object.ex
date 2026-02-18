defmodule UsaspendingMcp.Types.PSCCodeObject do
  @moduledoc """
  Represents a PSC (Product/Service Code) filter for USASpending API search endpoints.

  Values are hierarchical arrays representing classification levels,
  e.g. `["Service", "B", "B5", "B502"]`.

  ## Fields

    * `require` - (optional) PSC code paths to include
    * `exclude` - (optional) PSC code paths to exclude
  """

  defstruct [:require, :exclude]

  @type psc_path :: [String.t()]

  @type t :: %__MODULE__{
          require: [psc_path()] | nil,
          exclude: [psc_path()] | nil
        }

  @doc "Build a PSCCodeObject that requires the given code paths."
  def require(paths) when is_list(paths), do: %__MODULE__{require: paths}

  @doc "Build a PSCCodeObject that excludes the given code paths."
  def exclude(paths) when is_list(paths), do: %__MODULE__{exclude: paths}

  @doc "Build a PSCCodeObject with both require and exclude lists."
  def new(require_paths, exclude_paths) do
    %__MODULE__{require: require_paths, exclude: exclude_paths}
  end

  @doc "Convert to a map suitable for JSON encoding in API requests."
  def to_map(%__MODULE__{} = psc) do
    %{}
    |> maybe_put(:require, psc.require)
    |> maybe_put(:exclude, psc.exclude)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
