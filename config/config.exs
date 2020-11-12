# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :bank_account,
  ecto_repos: [BankAccount.Repo]

# Configures the endpoint
config :bank_account, BankAccountWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "T1RTYfbbk57iye+bEk3jJtQC9CYGnVO+rrYL3ots5NH148bd3DbcbZzwRafFEpGx",
  render_errors: [view: BankAccountWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: BankAccount.PubSub,
  live_view: [signing_salt: "Qz4goLVI"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
