defmodule BankAccount.Accounts.Guardian do
  use Guardian, otp_app: :bank_account

  alias BankAccount.Accounts

  def subject_for_token(client, _claims) do
    {:ok, to_string(client.id)}
  end

  def resource_from_claims(%{"sub" => id}) do
    client = Accounts.get_client!(id)
    {:ok, client}
  rescue
    Ecto.NoResultsError -> {:error, :resource_not_found}
  end
end
