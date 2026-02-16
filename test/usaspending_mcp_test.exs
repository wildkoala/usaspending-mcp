defmodule UsaspendingMcpTest do
  use ExUnit.Case

  test "API client module is available" do
    assert Code.ensure_loaded?(UsaspendingMcp.ApiClient)
  end

  test "server module is available" do
    assert Code.ensure_loaded?(UsaspendingMcp.Server)
  end
end
