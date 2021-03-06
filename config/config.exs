# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :tsg_global,
  ecto_repos: [TsgGlobal.Repo]

# Configures the endpoint
config :tsg_global, TsgGlobalWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: TsgGlobalWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: TsgGlobal.PubSub,
  live_view: [signing_salt: "UtVIDpaK"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tsg_global, :mix_env, Mix.env()

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
