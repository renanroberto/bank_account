defmodule BankAccount.Repo do
  use Ecto.Repo,
    otp_app: :bank_account,
    adapter: Ecto.Adapters.Postgres
end
