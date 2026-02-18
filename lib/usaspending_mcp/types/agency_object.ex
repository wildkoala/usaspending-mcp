defmodule UsaspendingMcp.Types.AgencyObject do
  @moduledoc """
  Represents an agency filter for USASpending API search endpoints.

  ## Fields

    * `type` - (required) `"awarding"` or `"funding"`
    * `tier` - (required) `"toptier"` or `"subtier"`
    * `name` - (required) agency name
    * `toptier_name` - (optional) only applicable when tier is `"subtier"`.
      Scopes subtiers with common names to a specific toptier.
      For example, several agencies have an "Office of Inspector General".
      If not provided, subtiers may span more than one toptier.
  """

  @enforce_keys [:type, :tier, :name]
  defstruct [:type, :tier, :name, :toptier_name]

  @type t :: %__MODULE__{
          type: :awarding | :funding,
          tier: :toptier | :subtier,
          name: String.t(),
          toptier_name: String.t() | nil
        }

  @valid_types ~w(awarding funding)

  @doc "Build an AgencyObject for a toptier agency."
  def toptier(type, name) when type in @valid_types do
    %__MODULE__{type: type, tier: "toptier", name: name}
  end

  @doc "Build an AgencyObject for a subtier agency."
  def subtier(type, name, toptier_name \\ nil) when type in @valid_types do
    %__MODULE__{type: type, tier: "subtier", name: name, toptier_name: toptier_name}
  end

  @doc "Convert to a map suitable for JSON encoding in API requests."
  def to_map(%__MODULE__{} = agency) do
    base = %{type: agency.type, tier: agency.tier, name: agency.name}

    if agency.tier == "subtier" && agency.toptier_name do
      Map.put(base, :toptier_name, agency.toptier_name)
    else
      base
    end
  end

  @doc "Build a list of AgencyObject structs from tool params."
  def from_params(params) do
    agency_filters =
      case Map.get(params, "agency") do
        nil -> []
        name -> [toptier(Map.get(params, "agency_type", "funding"), name)]
      end

    case Map.get(params, "subagency") do
      nil -> agency_filters
      name -> [subtier(Map.get(params, "agency_type", "funding"), name) | agency_filters]
    end
  end
end
