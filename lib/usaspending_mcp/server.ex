defmodule UsaspendingMcp.Server do
  @moduledoc """
  MCP Server for the USASpending API.

  Exposes federal spending data tools via the Model Context Protocol.
  """

  use Hermes.Server,
    name: "usaspending",
    version: "0.1.0",
    capabilities: [:tools]

  component UsaspendingMcp.Tools.SearchSpendingByAward, name: "search_spending_by_award"
  component UsaspendingMcp.Tools.SearchSpendingByAwardCount, name: "search_spending_by_award_count"
  component UsaspendingMcp.Tools.SpendingExplorer, name: "get_spending_explorer"
  component UsaspendingMcp.Tools.SpendingByCategory, name: "spending_by_category"
  component UsaspendingMcp.Tools.ListAgencies, name: "list_agencies"
  component UsaspendingMcp.Tools.ListSubagencies, name: "list_subagencies"
  component UsaspendingMcp.Tools.GetAwardDetails, name: "get_award_details"
  component UsaspendingMcp.Tools.GetRecipientProfile, name: "get_recipient_profile"
  component UsaspendingMcp.Tools.ListFederalAccounts, name: "list_federal_accounts"
end
