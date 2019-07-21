# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :crit,
  ecto_repos: [Crit.Repo]

# Configures the endpoint
config :crit, CritWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "0ILvFe/1UDwjJdW2uslLEAfGjUtIotwL5k2TqVE4pxVASZm9KI0lpg1wvtApWHmP",
  render_errors: [view: CritWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Crit.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason


## Within-app interfaces

config :crit, :audit_server, Servers.Audit




# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
