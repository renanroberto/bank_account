# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
use Mix.Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :bank_account, BankAccount.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :bank_account, BankAccountWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

secret_key_guardian =
  System.get_env("SECRET_KEY_GUARDIAN") ||
    raise """
    environment variable SECRET_KEY_GUARDIAN is missing.
    You can generate one by calling: mix guardian.gen.secret
    """

config :bank_account, BankAccount.Accounts.Guardian,
  issuer: "bank_account",
  secret_key: secret_key_guardian

secret_key_cloak =
  System.get_env("SECRET_KEY_CLOAK") ||
    raise """
    environment variable SECRET_KEY_CLOAK is missing.
    You can generate one on iex by calling:
    32 |> :crypto.strong_rand_bytes() |> Base.encode64()
    """

config :bank_account, BankAccount.Vault,
  ciphers: [
    default:
      {Cloak.Ciphers.AES.GCM,
       tag: "AES.GCM.V1", key: Base.decode64!("MPF+6wgvvyQZ3DQIp9BnsLIsqLdTGfge0LEhq8B2KcM=")}
  ]

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :bank_account, BankAccountWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
