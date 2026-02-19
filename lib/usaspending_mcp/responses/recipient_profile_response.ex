defmodule UsaspendingMcp.Responses.RecipientProfileResponse do
  @moduledoc "Response from the recipient profile endpoint"

  defmodule AmountsByType do
    defstruct [:contracts, :grants, :loans, :direct_payments, :other]

    @type t :: %__MODULE__{
            contracts: number() | nil,
            grants: number() | nil,
            loans: number() | nil,
            direct_payments: number() | nil,
            other: number() | nil
          }

    def from_map(nil), do: %__MODULE__{}

    def from_map(map) do
      %__MODULE__{
        contracts: map["contracts"],
        grants: map["grants"],
        loans: map["loans"],
        direct_payments: map["direct_payments"],
        other: map["other"]
      }
    end
  end

  defstruct [
    :name,
    :duns,
    :uei,
    :recipient_id,
    :parent_name,
    :location,
    :business_types,
    :total_transaction_amount,
    :total_awards,
    :amounts_by_type
  ]

  @type t :: %__MODULE__{
          name: String.t() | nil,
          duns: String.t() | nil,
          uei: String.t() | nil,
          recipient_id: String.t() | nil,
          parent_name: String.t() | nil,
          location: map(),
          business_types: [String.t()] | nil,
          total_transaction_amount: number() | nil,
          total_awards: integer() | nil,
          amounts_by_type: AmountsByType.t()
        }

  def from_map(data) when is_map(data) do
    %__MODULE__{
      name: data["name"],
      duns: data["duns"],
      uei: data["uei"],
      recipient_id: data["recipient_id"],
      parent_name: data["parent_name"],
      location: data["location"] || %{},
      business_types: data["business_types"],
      total_transaction_amount: data["total_transaction_amount"],
      total_awards: data["total_awards"],
      amounts_by_type: AmountsByType.from_map(data["total_amounts_by_award_type"])
    }
  end
end
