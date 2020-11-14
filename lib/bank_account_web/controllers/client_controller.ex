defmodule BankAccountWeb.ClientController do
  use BankAccountWeb, :controller

  alias BankAccount.Accounts
  alias BankAccountWeb.ErrorResponse

  def upsert(conn, %{"cpf" => cpf} = params) do
    invalid_params = [
      "credential",
      "refered_id"
    ]

    params = Map.drop(params, invalid_params)

    email = params["email"]
    password = params["password"]
    credential = %{email: email, password: password}

    with true <- CPF.valid?(cpf),
         {:ok, referral} <- get_referral(params["code"]) do
      params = Map.merge(params, referral)

      case Accounts.get_client_by_cpf(cpf) do
        {:ok, client} ->
          update(conn, client, params)

        {:error, :client_not_found} ->
          create(conn, Map.put(params, "credential", credential))
      end
    else
      false ->
        ErrorResponse.bad_request(conn, "invalid CPF")

      {:error, :referral_not_found} ->
        ErrorResponse.bad_request(conn, "invalid referral code")

      _ ->
        ErrorResponse.internal_error(conn)
    end
  end

  def upsert(conn, _params) do
    ErrorResponse.bad_request(conn, "CPF is required")
  end

  defp create(conn, params) do
    case Accounts.create_client(params) do
      {:ok, client} ->
        conn
        |> put_status(201)
        |> render("client.json", data: client)

      {:error, changeset} ->
        ErrorResponse.bad_request(conn, changeset)
    end
  end

  defp update(conn, client, params) do
    case Accounts.update_client(client, params) do
      {:ok, updated_client} ->
        conn
        |> render("client.json", data: updated_client)

      {:error, :client_not_found} ->
        ErrorResponse.not_found(conn, "client")

      {:error, changeset} ->
        ErrorResponse.bad_request(conn, changeset)
    end
  end

  defp get_referral(code) when is_binary(code) do
    with {:ok, referral} <- Accounts.get_referral(code) do
      {:ok, %{"refered_id" => referral.id}}
    end
  end

  defp get_referral(_code), do: {:ok, %{}}
end
