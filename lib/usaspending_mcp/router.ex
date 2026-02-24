defmodule UsaspendingMcp.Router do
  use Plug.Router

  require Logger

  plug Plug.Logger, log: :info
  plug :log_request_details
  plug :match
  plug :dispatch

  forward "/", to: UsaspendingMcp.McpPlug,
    init_opts: [server: UsaspendingMcp.Server, timeout: 60_000]

  defp log_request_details(conn, _opts) do
    Logger.info(
      "MCP request: #{conn.method} #{conn.request_path} from #{:inet.ntoa(conn.remote_ip)} " <>
        "headers=#{inspect(relevant_headers(conn))}"
    )

    Plug.Conn.register_before_send(conn, fn conn ->
      Logger.info(
        "MCP response: #{conn.status} for #{conn.method} #{conn.request_path}"
      )

      conn
    end)
  end

  defp relevant_headers(conn) do
    conn.req_headers
    |> Enum.filter(fn {k, _v} ->
      k in ["accept", "content-type", "mcp-session-id", "origin", "host", "user-agent"]
    end)
    |> Map.new()
  end
end
