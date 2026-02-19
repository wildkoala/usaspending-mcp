defmodule UsaspendingMcp.Responses.AgencyListResponse do
  @moduledoc "Response from the toptier agencies list endpoint"

  defmodule Agency do
    defstruct [
      :agency_name,
      :budget_authority_amount,
      :obligated_amount,
      :outlay_amount,
      :percentage_of_total_budget_authority,
      :active_fy
    ]

    @type t :: %__MODULE__{
            agency_name: String.t() | nil,
            budget_authority_amount: number() | nil,
            obligated_amount: number() | nil,
            outlay_amount: number() | nil,
            percentage_of_total_budget_authority: number() | nil,
            active_fy: String.t() | integer() | nil
          }

    def from_map(map) do
      %__MODULE__{
        agency_name: map["agency_name"],
        budget_authority_amount: map["budget_authority_amount"],
        obligated_amount: map["obligated_amount"],
        outlay_amount: map["outlay_amount"],
        percentage_of_total_budget_authority: map["percentage_of_total_budget_authority"],
        active_fy: map["active_fy"]
      }
    end
  end

  defstruct [:agencies]

  @type t :: %__MODULE__{agencies: [Agency.t()]}

  def from_map(%{"results" => results}) do
    %__MODULE__{
      agencies: Enum.map(results, &Agency.from_map/1)
    }
  end

  def from_map(_), do: nil
end
