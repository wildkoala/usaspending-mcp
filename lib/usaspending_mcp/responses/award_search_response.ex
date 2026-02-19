defmodule UsaspendingMcp.Responses.AwardSearchResponse do
  @moduledoc "Response from the search spending by award endpoint"

  defmodule CodeField do
    defstruct [:code, :description]

    @type t :: %__MODULE__{
            code: String.t() | nil,
            description: String.t() | nil
          }

    def from_map(nil), do: nil
    def from_map(%{"code" => code} = map), do: %__MODULE__{code: code, description: map["description"]}
    def from_map(value) when is_binary(value), do: %__MODULE__{code: value, description: nil}
    def from_map(_), do: nil
  end

  defmodule Award do
    defstruct [
      :award_id,
      :recipient_name,
      :award_amount,
      :total_outlays,
      :description,
      :start_date,
      :end_date,
      :awarding_agency,
      :awarding_sub_agency,
      :naics,
      :psc,
      :cfda_number,
      :generated_internal_id
    ]

    @type t :: %__MODULE__{
            award_id: String.t() | nil,
            recipient_name: String.t() | nil,
            award_amount: number() | nil,
            total_outlays: number() | nil,
            description: String.t() | nil,
            start_date: String.t() | nil,
            end_date: String.t() | nil,
            awarding_agency: String.t() | nil,
            awarding_sub_agency: String.t() | nil,
            naics: CodeField.t() | nil,
            psc: CodeField.t() | nil,
            cfda_number: String.t() | nil,
            generated_internal_id: String.t() | nil
          }

    def from_map(map) do
      %__MODULE__{
        award_id: map["Award ID"],
        recipient_name: map["Recipient Name"],
        award_amount: map["Award Amount"],
        total_outlays: map["Total Outlays"],
        description: map["Description"],
        start_date: map["Start Date"],
        end_date: map["End Date"],
        awarding_agency: map["Awarding Agency"],
        awarding_sub_agency: map["Awarding Sub Agency"],
        naics: CodeField.from_map(map["NAICS"]),
        psc: CodeField.from_map(map["PSC"]),
        cfda_number: map["CFDA Number"],
        generated_internal_id: map["generated_internal_id"]
      }
    end
  end

  defstruct [:results, :total, :page]

  @type t :: %__MODULE__{
          results: [Award.t()],
          total: integer(),
          page: integer()
        }

  def from_map(%{"results" => results, "page_metadata" => meta}) do
    %__MODULE__{
      results: Enum.map(results, &Award.from_map/1),
      total: meta["total"] || 0,
      page: meta["page"] || 1
    }
  end

  def from_map(_), do: nil
end
