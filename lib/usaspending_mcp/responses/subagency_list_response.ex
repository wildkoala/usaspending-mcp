defmodule UsaspendingMcp.Responses.SubagencyListResponse do
  @moduledoc "Response from the sub-agency list endpoint"

  defmodule Office do
    defstruct [:name, :code, :total_obligations]

    @type t :: %__MODULE__{
            name: String.t() | nil,
            code: String.t() | nil,
            total_obligations: number() | nil
          }

    def from_map(map) do
      %__MODULE__{
        name: map["name"],
        code: map["code"],
        total_obligations: map["total_obligations"]
      }
    end
  end

  defmodule Subagency do
    defstruct [:name, :abbreviation, :total_obligations, :transaction_count, :new_award_count, :children]

    @type t :: %__MODULE__{
            name: String.t() | nil,
            abbreviation: String.t() | nil,
            total_obligations: number() | nil,
            transaction_count: integer() | nil,
            new_award_count: integer() | nil,
            children: [Office.t()]
          }

    def from_map(map) do
      children =
        case map["children"] do
          list when is_list(list) -> Enum.map(list, &Office.from_map/1)
          _ -> []
        end

      %__MODULE__{
        name: map["name"],
        abbreviation: map["abbreviation"],
        total_obligations: map["total_obligations"],
        transaction_count: map["transaction_count"],
        new_award_count: map["new_award_count"],
        children: children
      }
    end
  end

  defstruct [:toptier_code, :fiscal_year, :results, :total, :page]

  @type t :: %__MODULE__{
          toptier_code: String.t() | nil,
          fiscal_year: integer() | nil,
          results: [Subagency.t()],
          total: integer(),
          page: integer()
        }

  def from_map(%{"results" => results, "toptier_code" => code, "fiscal_year" => fy} = data) do
    %__MODULE__{
      toptier_code: code,
      fiscal_year: fy,
      results: Enum.map(results, &Subagency.from_map/1),
      total: get_in(data, ["page_metadata", "total"]) || length(results),
      page: get_in(data, ["page_metadata", "page"]) || 1
    }
  end

  def from_map(_), do: nil
end
