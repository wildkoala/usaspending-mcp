defmodule UsaspendingMcp.Types.TreasuryAccountComponentsObject do
  @moduledoc """
  Represents a Treasury Account component filter for USASpending API search endpoints.

  ## Fields

    * `aid` - (required) Agency Identifier — three characters
    * `main` - (required) Main Account Code — four digits
    * `ata` - (optional) Allocation Transfer Agency Identifier — three characters
    * `bpoa` - (optional) Beginning Period of Availability — four digits
    * `epoa` - (optional) Ending Period of Availability — four digits
    * `a` - (optional) Availability Type Code — `"X"` or nil
    * `sub` - (optional) Sub-Account Code — three digits
  """

  @enforce_keys [:aid, :main]
  defstruct [:aid, :main, :ata, :bpoa, :epoa, :a, :sub]

  @type t :: %__MODULE__{
          aid: String.t(),
          main: String.t(),
          ata: String.t() | nil,
          bpoa: String.t() | nil,
          epoa: String.t() | nil,
          a: String.t() | nil,
          sub: String.t() | nil
        }

  @doc "Build a TreasuryAccountComponentsObject with required fields."
  def new(aid, main, opts \\ []) do
    %__MODULE__{
      aid: aid,
      main: main,
      ata: Keyword.get(opts, :ata),
      bpoa: Keyword.get(opts, :bpoa),
      epoa: Keyword.get(opts, :epoa),
      a: Keyword.get(opts, :a),
      sub: Keyword.get(opts, :sub)
    }
  end

  @doc "Convert to a map suitable for JSON encoding in API requests."
  def to_map(%__MODULE__{} = tac) do
    %{aid: tac.aid, main: tac.main}
    |> maybe_put(:ata, tac.ata)
    |> maybe_put(:bpoa, tac.bpoa)
    |> maybe_put(:epoa, tac.epoa)
    |> maybe_put(:a, tac.a)
    |> maybe_put(:sub, tac.sub)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
