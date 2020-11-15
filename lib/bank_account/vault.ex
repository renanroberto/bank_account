defmodule BankAccount.Vault do
  @moduledoc "Provide a vault so Cloak can encrypt some fields"

  use Cloak.Vault, otp_app: :bank_account
end
