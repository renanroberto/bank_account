defmodule BankAccount.CodeGenerator do
  import Ecto.Query, warn: false
  alias BankAccount.Repo

  alias BankAccount.Referral
  alias BankAccount.Accounts.Client

  def gen_code(%Client{} = client) do
    limit = 100_000_000

    case full?(limit) do
      {:ok, :codes_available} ->
        code = :rand.uniform(limit) - 1

        query =
          from referral in Referral,
            where: referral.code == ^code

        if Repo.exists?(query) do
          gen_code(client)
        else
          with {:ok, referral} <- insert_referral(client, code),
               do: {:ok, num_to_code(referral.code)}
        end

      error ->
        error
    end
  end

  defp num_to_code(num) do
    num
    |> Integer.to_string()
    |> String.pad_leading(8, "0")
  end

  defp insert_referral(client, code) do
    %Referral{}
    |> Referral.changeset(%{code: code, client_id: client.id})
    |> Repo.insert()
  end

  defp full?(limit) do
    query = from r in Referral, select: count()

    if Repo.one(query) < limit do
      {:ok, :codes_available}
    else
      {:error, :codes_sold_out}
    end
  end
end
