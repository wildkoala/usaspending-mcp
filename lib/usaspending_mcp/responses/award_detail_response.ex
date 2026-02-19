defmodule UsaspendingMcp.Responses.AwardDetailResponse do
  @moduledoc "Response from the award details endpoint"

  defmodule Recipient do
    defstruct [:name, :hash, :location]

    @type t :: %__MODULE__{
            name: String.t() | nil,
            hash: String.t() | nil,
            location: map() | nil
          }

    def from_map(nil), do: %__MODULE__{}

    def from_map(map) do
      %__MODULE__{
        name: map["recipient_name"],
        hash: map["recipient_hash"],
        location: map["location"]
      }
    end
  end

  defmodule CfdaInfo do
    defstruct [:number, :title]

    @type t :: %__MODULE__{
            number: String.t() | nil,
            title: String.t() | nil
          }

    def from_map(map) do
      %__MODULE__{
        number: map["cfda_number"],
        title: map["cfda_title"]
      }
    end
  end

  defstruct [
    :award_id,
    :type_description,
    :type,
    :category,
    :description,
    :total_obligation,
    :base_and_all_options_value,
    :total_outlays,
    :recipient,
    :funding_agency_name,
    :place_of_performance,
    :start_date,
    :end_date,
    :naics_description,
    :psc_description,
    :cfda_info
  ]

  @type t :: %__MODULE__{
          award_id: String.t() | nil,
          type_description: String.t() | nil,
          type: String.t() | nil,
          category: String.t() | nil,
          description: String.t() | nil,
          total_obligation: number() | nil,
          base_and_all_options_value: number() | nil,
          total_outlays: number() | nil,
          recipient: Recipient.t(),
          funding_agency_name: String.t() | nil,
          place_of_performance: map() | nil,
          start_date: String.t() | nil,
          end_date: String.t() | nil,
          naics_description: String.t() | nil,
          psc_description: String.t() | nil,
          cfda_info: [CfdaInfo.t()]
        }

  def from_map(data) when is_map(data) do
    period = data["period_of_performance"] || %{}
    agency = data["funding_agency"] || %{}
    agency_detail = agency["toptier_agency"] || %{}

    cfda_info =
      case data["cfda_info"] do
        list when is_list(list) -> Enum.map(list, &CfdaInfo.from_map/1)
        _ -> []
      end

    %__MODULE__{
      award_id: data["generated_unique_award_id"],
      type_description: data["type_description"],
      type: data["type"],
      category: data["category"],
      description: data["description"],
      total_obligation: data["total_obligation"],
      base_and_all_options_value: data["base_and_all_options_value"],
      total_outlays: data["total_outlays"],
      recipient: Recipient.from_map(data["recipient"]),
      funding_agency_name: agency_detail["name"],
      place_of_performance: data["place_of_performance"],
      start_date: period["start_date"],
      end_date: period["end_date"],
      naics_description: data["naics_description"],
      psc_description: data["psc_description"],
      cfda_info: cfda_info
    }
  end
end
