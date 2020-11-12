defmodule BankAccount.Encrypted.Date do
  @moduledoc "Provide date encryption for cloak"

  use Cloak.Ecto.Date, vault: BankAccount.Vault
end
