import Config

# Suppress all logging to stderr since MCP uses stdio transport
# and log output would interfere with the JSON-RPC protocol.
# Only errors go to stderr.
config :logger, level: :error
