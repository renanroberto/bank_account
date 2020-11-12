defmodule BankAccount.Encrypted.Date do
  use Cloak.Ecto.Date, vault: BankAccount.Vault
end
