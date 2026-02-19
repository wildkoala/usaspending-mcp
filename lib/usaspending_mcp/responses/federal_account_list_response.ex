defmodule UsaspendingMcp.Responses.FederalAccountListResponse do
  @moduledoc "Response from the federal accounts list endpoint"

  defmodule Account do
    defstruct [:account_name, :account_number, :managing_agency, :managing_agency_acronym, :budgetary_resources]

    @type t :: %__MODULE__{
            account_name: String.t() | nil,
            account_number: String.t() | nil,
            managing_agency: String.t() | nil,
            managing_agency_acronym: String.t() | nil,
            budgetary_resources: number() | nil
          }

    def from_map(map) do
      %__MODULE__{
        account_name: map["account_name"],
        account_number: map["account_number"],
        managing_agency: map["managing_agency"],
        managing_agency_acronym: map["managing_agency_acronym"],
        budgetary_resources: map["budgetary_resources"]
      }
    end
  end

  defstruct [:accounts, :total, :page]

  @type t :: %__MODULE__{
          accounts: [Account.t()],
          total: integer(),
          page: integer()
        }

  def from_map(%{"results" => results, "page_metadata" => meta}) do
    %__MODULE__{
      accounts: Enum.map(results, &Account.from_map/1),
      total: meta["total"] || 0,
      page: meta["page"] || 1
    }
  end

  def from_map(_), do: nil
end
