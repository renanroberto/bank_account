defmodule BankAccount.Encrypted.Binary do
  @moduledoc "Provide binary encryption for cloak"

  use Cloak.Ecto.Binary, vault: BankAccount.Vault
end
