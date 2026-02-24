defmodule UsaspendingMcp.McpPlug do
  @moduledoc """
  Custom MCP plug that wraps the Hermes StreamableHTTP plug to fix the
  GenServer.call timeout bug in handle_message_for_sse/4.

  The upstream Hermes plug calls `StreamableHTTP.handle_message_for_sse/4`
  which uses the default 5000ms GenServer.call timeout. Tool calls that hit
  external APIs (like USASpending) routinely exceed this, causing timeouts
  and client retry loops.

  This plug calls GenServer.call directly with a configurable timeout
  (default 60s) for the SSE request path, and delegates everything else
  to the Hermes plug.
  """

  @behaviour Plug

  require Logger

  import Plug.Conn

  alias Hermes.MCP.Error
  alias Hermes.MCP.ID
  alias Hermes.MCP.Message
  alias Hermes.Server.Transport.StreamableHTTP

  require Message

  @default_timeout 60_000

  @impl Plug
  def init(opts) do
    server = Keyword.fetch!(opts, :server)
    registry = Keyword.get(opts, :registry, Hermes.Server.Registry)
    transport = registry.transport(server, :streamable_http)
    session_header = Keyword.get(opts, :session_header, "mcp-session-id")
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    # Also init the upstream plug for non-SSE paths
    upstream_opts = Hermes.Server.Transport.StreamableHTTP.Plug.init(opts)

    %{
      transport: transport,
      session_header: session_header,
      timeout: timeout,
      upstream_opts: upstream_opts
    }
  end

  @impl Plug
  def call(conn, %{upstream_opts: upstream_opts} = opts) do
    # Only intercept POST requests that want SSE (the buggy path).
    # Everything else delegates to the upstream plug.
    if conn.method == "POST" and wants_sse?(conn) do
      handle_post_sse(conn, opts)
    else
      Hermes.Server.Transport.StreamableHTTP.Plug.call(conn, upstream_opts)
    end
  end

  defp handle_post_sse(conn, %{transport: transport, session_header: session_header, timeout: timeout}) do
    with {:ok, body, conn} <- read_body_safe(conn),
         {:ok, message} <- parse_message(body) do
      session_id = get_or_create_session_id(conn, session_header)
      context = build_request_context(conn)

      Logger.info("MCP SSE request: #{message["method"]} (timeout=#{timeout}ms, session=#{session_id})")

      # This is the fix: call GenServer.call with our timeout instead of the default 5000ms
      result =
        GenServer.call(
          transport,
          {:handle_message_for_sse, session_id, message, context},
          timeout
        )

      handle_sse_result(conn, result, transport, session_id, message, context, session_header)
    else
      {:error, :invalid_accept_header} ->
        send_error(conn, 406, "Not Acceptable: Client must accept both application/json and text/event-stream")

      {:error, reason} ->
        Logger.error("MCP request parse error: #{inspect(reason)}")
        send_error(conn, 400, "Bad request: #{inspect(reason)}")
    end
  end

  defp handle_sse_result(conn, {:sse, response}, transport, session_id, _body, _context, _session_header) do
    if handler_pid = StreamableHTTP.get_sse_handler(transport, session_id) do
      send(handler_pid, {:sse_message, response})

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(202, "{}")
    else
      # No SSE handler registered, return as direct response
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, response || "{}")
    end
  end

  defp handle_sse_result(conn, {:ok, nil}, _transport, session_id, _body, _context, session_header) do
    # Notifications return {:ok, nil} from Hermes — respond with 202 empty body
    conn
    |> maybe_add_session_header(session_header, session_id)
    |> put_resp_content_type("application/json")
    |> send_resp(202, "{}")
  end

  defp handle_sse_result(conn, {:ok, response}, _transport, session_id, _body, _context, session_header) do
    conn
    |> maybe_add_session_header(session_header, session_id)
    |> put_resp_content_type("application/json")
    |> send_resp(200, response)
  end

  defp handle_sse_result(conn, {:error, %Error{} = error}, _transport, _session_id, body, _context, _session_header) do
    request_id = case body do
      %{"id" => id} -> id
      _ -> nil
    end
    error_id = request_id || ID.generate_error_id()
    {:ok, encoded} = Error.to_json_rpc(error, error_id)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, encoded)
  end

  defp handle_sse_result(conn, {:error, reason}, _transport, _session_id, _body, _context, _session_header) do
    Logger.error("MCP tool call error: #{inspect(reason)}")

    error = Error.protocol(:internal_error, %{reason: reason})
    {:ok, encoded} = Error.to_json_rpc(error, ID.generate_error_id())

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(500, encoded)
  end

  # Helpers

  defp wants_sse?(conn) do
    conn
    |> get_req_header("accept")
    |> List.first("")
    |> String.contains?("text/event-stream")
  end

  defp read_body_safe(conn) do
    case conn.body_params do
      %Plug.Conn.Unfetched{} ->
        Plug.Conn.read_body(conn, read_timeout: 30_000)

      body when is_map(body) ->
        {:ok, body, conn}
    end
  end

  defp parse_message(body) when is_binary(body) do
    case Message.decode(body) do
      {:ok, [message]} -> {:ok, message}
      {:ok, [message | _]} -> {:ok, message}
      {:error, reason} -> {:error, {:invalid_json, reason}}
    end
  end

  defp parse_message(body) when is_map(body) do
    case Message.validate_message(body) do
      {:ok, message} -> {:ok, message}
      {:error, reason} -> {:error, {:invalid_json, reason}}
    end
  end

  defp get_or_create_session_id(conn, session_header) do
    case get_req_header(conn, session_header) do
      [session_id] when is_binary(session_id) and session_id != "" -> session_id
      _ -> ID.generate_session_id()
    end
  end

  defp maybe_add_session_header(conn, session_header, session_id) do
    if get_req_header(conn, session_header) == [] do
      put_resp_header(conn, session_header, session_id)
    else
      conn
    end
  end

  defp build_request_context(conn) do
    %{
      assigns: conn.assigns,
      type: :http,
      req_headers: conn.req_headers,
      query_params: fetch_query_params_safe(conn),
      remote_ip: conn.remote_ip,
      scheme: conn.scheme,
      host: conn.host,
      port: conn.port,
      request_path: conn.request_path
    }
  end

  defp fetch_query_params_safe(conn) do
    case conn.query_params do
      %Plug.Conn.Unfetched{} -> nil
      params -> params
    end
  end

  defp send_error(conn, status, message) do
    error = Error.protocol(:internal_error, %{data: %{message: message, http_status: status}})
    {:ok, encoded} = Error.to_json_rpc(error, ID.generate_error_id())

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, encoded)
  end
end
