defmodule BankAccountWeb.ClientController do
  use BankAccountWeb, :controller

  alias BankAccount.Accounts

  def upsert(conn, %{"cpf" => cpf} = params) do
    invalid_params = [
      "active",
      "status_complete",
      "credential",
      "refered_id"
    ]

    params = Map.drop(params, invalid_params)

    email = params["email"]
    password = params["password"]
    credential = %{email: email, password: password}

    with true <- CPF.valid?(cpf),
         {:ok, referral} <- get_referral(params["code"]),
         params <- Map.put(params, "refered_id", Map.get(referral, :id)),
         {:ok, client} <- Accounts.get_client_by_cpf(cpf) do
      update(conn, client, params)
    else
      {:error, :client_not_found} ->
        create(conn, Map.put(params, "credential", credential))

      {:error, :referral_not_found} ->
        json(conn, %{error: "invalid referral code"})

      false ->
        json(conn, %{error: "invalid CPF"})

      error ->
        IO.inspect(error)
        json(conn, %{error: "something went wrong"})
    end
  end

  def upsert(conn, _params) do
    json(conn, %{error: "CPF is required"})
  end

  defp create(conn, params) do
    case Accounts.create_client(params) do
      {:ok, client} ->
        conn
        |> put_status(201)
        |> render("client.json", data: client)

      {:error, changeset} ->
        IO.inspect(changeset)
        json(conn, %{error: "something went wrong"})
    end
  end

  defp update(conn, client, params) do
    case Accounts.update_client(client, params) do
      {:ok, updated_client} ->
        conn
        |> render("client.json", data: updated_client)

      {:error, :client_not_found} ->
        json(conn, %{error: "client not found"})

      {:error, changeset} ->
        IO.inspect(changeset)
        json(conn, %{error: "something went wrong"})
    end
  end

  defp get_referral(code) when is_binary(code) do
    Accounts.get_referral(code)
  end

  defp get_referral(_code), do: {:ok, nil}
end
