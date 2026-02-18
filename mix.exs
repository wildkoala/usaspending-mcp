defmodule UsaspendingMcp.MixProject do
  use Mix.Project

  def project do
    [
      app: :usaspending_mcp,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {UsaspendingMcp.Application, []}
    ]
  end

  defp deps do
    [
      {:hermes_mcp, "~> 0.14"},
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:bandit, "~> 1.0"},
      {:plug, "~> 1.0"}
    ]
  end
end
