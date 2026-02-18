defmodule UsaspendingMcp.Types.TimePeriodObject do
  @moduledoc """
  Represents a time period filter for USASpending API search endpoints.

  ## Fields

    * `start_date` - (optional) start date in `YYYY-MM-DD` format
    * `end_date` - (optional) end date in `YYYY-MM-DD` format
  """

  defstruct [:start_date, :end_date]

  @type t :: %__MODULE__{
          start_date: String.t() | nil,
          end_date: String.t() | nil
        }

  @doc "Build a TimePeriodObject with start and end dates."
  def new(start_date, end_date) do
    %__MODULE__{start_date: start_date, end_date: end_date}
  end

  @doc "Convert to a map suitable for JSON encoding in API requests."
  def to_map(%__MODULE__{} = tp) do
    %{}
    |> maybe_put(:start_date, tp.start_date)
    |> maybe_put(:end_date, tp.end_date)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
