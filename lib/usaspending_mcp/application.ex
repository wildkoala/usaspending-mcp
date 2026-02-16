defmodule UsaspendingMcp.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      if Mix.env() == :test do
        []
      else
        [
          Hermes.Server.Registry,
          %{
            id: Hermes.Server.Supervisor,
            start:
              {Hermes.Server.Supervisor, :start_link,
               [UsaspendingMcp.Server, [transport: :stdio]]},
            type: :supervisor
          }
        ]
      end

    opts = [strategy: :one_for_one, name: UsaspendingMcp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
