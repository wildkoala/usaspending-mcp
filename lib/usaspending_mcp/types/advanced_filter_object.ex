defmodule UsaspendingMcp.Types.AdvancedFilterObject do
  @moduledoc """
  Represents the advanced filter object for USASpending API search endpoints.

  All fields are optional. Combines keyword search, time periods, location filters,
  agency filters, recipient filters, award type/amount filters, and various code-based filters.

  ## Fields

    * `keywords` - search keywords
    * `description` - description text search
    * `time_period` - list of `TimePeriodObject`
    * `place_of_performance_scope` - `"domestic"` or `"foreign"`
    * `place_of_performance_locations` - list of `LocationObject`
    * `agencies` - list of `AgencyObject`
    * `recipient_search_text` - text searched across recipient name, UEI, and DUNS
    * `recipient_scope` - `"domestic"` or `"foreign"`
    * `recipient_locations` - list of `LocationObject`
    * `recipient_type_names` - e.g. `["category_business", "sole_proprietorship"]`
    * `award_type_codes` - `FilterObjectAwardTypes` list of award type code strings
    * `award_ids` - award IDs (quote for exact match, e.g. `"SPE30018FLJFN"`)
    * `award_amounts` - list of `AwardAmounts` range filters
    * `program_numbers` - e.g. `["10.331"]`
    * `naics_codes` - `NAICSCodeObject`
    * `tas_codes` - list of `TASCodeObject`
    * `psc_codes` - `PSCCodeObject` or legacy array of code strings
    * `contract_pricing_type_codes` - e.g. `["J"]`
    * `set_aside_type_codes` - e.g. `["NONE"]`
    * `extent_competed_type_codes` - e.g. `["A"]`
    * `treasury_account_components` - list of `TreasuryAccountComponentsObject`
    * `object_class` - list of object class strings
    * `program_activity` - list of program activity numbers
  """

  alias UsaspendingMcp.Types.{
    AgencyObject,
    AwardAmounts,
    LocationObject,
    NAICSCodeObject,
    PSCCodeObject,
    TASCodeObject,
    TimePeriodObject,
    TreasuryAccountComponentsObject
  }

  defstruct [
    :keywords,
    :description,
    :time_period,
    :place_of_performance_scope,
    :place_of_performance_locations,
    :agencies,
    :recipient_search_text,
    :recipient_scope,
    :recipient_locations,
    :recipient_type_names,
    :award_type_codes,
    :award_ids,
    :award_amounts,
    :program_numbers,
    :naics_codes,
    :tas_codes,
    :psc_codes,
    :contract_pricing_type_codes,
    :set_aside_type_codes,
    :extent_competed_type_codes,
    :treasury_account_components,
    :object_class,
    :program_activity
  ]

  @type t :: %__MODULE__{
          keywords: [String.t()] | nil,
          description: String.t() | nil,
          time_period: [TimePeriodObject.t()] | nil,
          place_of_performance_scope: String.t() | nil,
          place_of_performance_locations: [LocationObject.t()] | nil,
          agencies: [AgencyObject.t()] | nil,
          recipient_search_text: [String.t()] | nil,
          recipient_scope: String.t() | nil,
          recipient_locations: [LocationObject.t()] | nil,
          recipient_type_names: [String.t()] | nil,
          award_type_codes: [String.t()] | nil,
          award_ids: [String.t()] | nil,
          award_amounts: [AwardAmounts.t()] | nil,
          program_numbers: [String.t()] | nil,
          naics_codes: NAICSCodeObject.t() | nil,
          tas_codes: [TASCodeObject.t()] | nil,
          psc_codes: PSCCodeObject.t() | [String.t()] | nil,
          contract_pricing_type_codes: [String.t()] | nil,
          set_aside_type_codes: [String.t()] | nil,
          extent_competed_type_codes: [String.t()] | nil,
          treasury_account_components: [TreasuryAccountComponentsObject.t()] | nil,
          object_class: [String.t()] | nil,
          program_activity: [number()] | nil
        }

  @doc "Convert to a map suitable for JSON encoding in API requests."
  def to_map(%__MODULE__{} = filter) do
    %{}
    |> maybe_put(:keywords, filter.keywords)
    |> maybe_put(:description, filter.description)
    |> maybe_put_mapped(:time_period, filter.time_period, &TimePeriodObject.to_map/1)
    |> maybe_put(:place_of_performance_scope, filter.place_of_performance_scope)
    |> maybe_put_mapped(:place_of_performance_locations, filter.place_of_performance_locations, &LocationObject.to_map/1)
    |> maybe_put_mapped(:agencies, filter.agencies, &AgencyObject.to_map/1)
    |> maybe_put(:recipient_search_text, filter.recipient_search_text)
    |> maybe_put(:recipient_scope, filter.recipient_scope)
    |> maybe_put_mapped(:recipient_locations, filter.recipient_locations, &LocationObject.to_map/1)
    |> maybe_put(:recipient_type_names, filter.recipient_type_names)
    |> maybe_put(:award_type_codes, filter.award_type_codes)
    |> maybe_put(:award_ids, filter.award_ids)
    |> maybe_put_mapped(:award_amounts, filter.award_amounts, &AwardAmounts.to_map/1)
    |> maybe_put(:program_numbers, filter.program_numbers)
    |> maybe_put_nested(:naics_codes, filter.naics_codes, &NAICSCodeObject.to_map/1)
    |> maybe_put_mapped(:tas_codes, filter.tas_codes, &TASCodeObject.to_map/1)
    |> maybe_put_psc_codes(filter.psc_codes)
    |> maybe_put(:contract_pricing_type_codes, filter.contract_pricing_type_codes)
    |> maybe_put(:set_aside_type_codes, filter.set_aside_type_codes)
    |> maybe_put(:extent_competed_type_codes, filter.extent_competed_type_codes)
    |> maybe_put_mapped(:treasury_account_components, filter.treasury_account_components, &TreasuryAccountComponentsObject.to_map/1)
    |> maybe_put(:object_class, filter.object_class)
    |> maybe_put(:program_activity, filter.program_activity)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_mapped(map, _key, nil, _mapper), do: map
  defp maybe_put_mapped(map, key, list, mapper), do: Map.put(map, key, Enum.map(list, mapper))

  defp maybe_put_nested(map, _key, nil, _mapper), do: map
  defp maybe_put_nested(map, key, value, mapper), do: Map.put(map, key, mapper.(value))

  # psc_codes supports both PSCCodeObject and legacy array of strings
  defp maybe_put_psc_codes(map, nil), do: map
  defp maybe_put_psc_codes(map, %PSCCodeObject{} = psc), do: Map.put(map, :psc_codes, PSCCodeObject.to_map(psc))
  defp maybe_put_psc_codes(map, codes) when is_list(codes), do: Map.put(map, :psc_codes, codes)
end
