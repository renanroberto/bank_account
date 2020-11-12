defmodule BankAccount.Encrypted.Binary do
  use Cloak.Ecto.Binary, vault: BankAccount.Vault
end
