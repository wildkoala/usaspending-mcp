defmodule UsaspendingMcp.Responses.AwardCountResponse do
  @moduledoc "Response from the spending by award count endpoint"

  defstruct [:counts]

  @type t :: %__MODULE__{counts: %{String.t() => integer()}}

  def from_map(%{"results" => results}) when is_map(results) do
    %__MODULE__{counts: results}
  end

  def from_map(_), do: nil
end
