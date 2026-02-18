defmodule UsaspendingMcp.Types.FilterObjectAwardTypes do
  @moduledoc """
  Filterable award type codes for USASpending API search endpoints.

  ## Award Type Codes

  **Contracts:** `A`, `B`, `C`, `D`

  **IDV (Indefinite Delivery Vehicles):** `IDV_A`, `IDV_B`, `IDV_B_A`, `IDV_B_B`, `IDV_B_C`, `IDV_C`, `IDV_D`, `IDV_E`

  **Grants:** `02`, `03`, `04`, `05`

  **Direct Payments:** `06`, `10`

  **Loans:** `07`, `08`

  **Other:** `09`, `11`
  """

  @valid_codes ~w(
    02 03 04 05 06 07 08 09 10 11
    A B C D
    IDV_A IDV_B IDV_B_A IDV_B_B IDV_B_C IDV_C IDV_D IDV_E
  )

  @contracts ~w(A B C D)
  @idvs ~w(IDV_A IDV_B IDV_B_A IDV_B_B IDV_B_C IDV_C IDV_D IDV_E)
  @grants ~w(02 03 04 05)
  @direct_payments ~w(06 10)
  @loans ~w(07 08)
  @other ~w(09 11)

  def valid_codes, do: @valid_codes
  def contracts, do: @contracts
  def idvs, do: @idvs
  def grants, do: @grants
  def direct_payments, do: @direct_payments
  def loans, do: @loans
  def other, do: @other

  @doc "All contract-related codes (contracts + IDVs)."
  def all_contracts, do: @contracts ++ @idvs

  @doc "All assistance codes (grants, direct payments, loans, other)."
  def all_assistance, do: @grants ++ @direct_payments ++ @loans ++ @other

  @doc "Check if a code is valid."
  def valid?(code), do: code in @valid_codes
end
