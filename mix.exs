defmodule UsaspendingMcp.MixProject do
  use Mix.Project

  def project do
    [
      app: :usaspending_mcp,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
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
      {:jason, "~> 1.4"}
    ]
  end

  # Run `mix setup` after cloning to fetch deps and apply patches.
  defp aliases do
    [
      setup: [
        "deps.get",
        &patch_hermes_stdio/1,
        "deps.compile hermes_mcp --force"
      ]
    ]
  end

  # Patches hermes_mcp STDIO transport to iterate over the message list
  # returned by Message.decode/1. Without this, the server crashes with
  # BadMapError on every incoming STDIO message.
  defp patch_hermes_stdio(_) do
    file = "deps/hermes_mcp/lib/hermes/server/transport/stdio.ex"

    content = File.read!(file)

    patched =
      String.replace(
        content,
        "process_message(messages, state)",
        "Enum.each(messages, &process_message(&1, state))"
      )

    if content != patched do
      File.write!(file, patched)
      Mix.shell().info("Patched hermes_mcp STDIO transport")
    end
  end
end
