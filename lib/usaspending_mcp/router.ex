defmodule UsaspendingMcp.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  forward "/", to: Hermes.Server.Transport.StreamableHTTP.Plug,
    init_opts: [server: UsaspendingMcp.Server]
end
