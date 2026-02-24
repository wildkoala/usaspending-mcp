defmodule UsaspendingMcp.Application do
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    children =
      if Mix.env() == :test do
        []
      else
        Logger.info("Starting UsaspendingMcp server on 0.0.0.0:4005")

        [
          Hermes.Server.Registry,
          %{
            id: Hermes.Server.Supervisor,
            start:
              {Hermes.Server.Supervisor, :start_link,
               [UsaspendingMcp.Server, [transport: {:streamable_http, start: true}]]},
            type: :supervisor
          },
          {Bandit, plug: UsaspendingMcp.Router, port: 4005, ip: {0, 0, 0, 0}}
        ]
      end

    opts = [strategy: :one_for_one, name: UsaspendingMcp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
