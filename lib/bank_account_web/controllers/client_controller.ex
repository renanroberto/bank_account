defmodule BankAccountWeb.ClientController do
  use BankAccountWeb, :controller

  alias BankAccount.Accounts
  alias BankAccountWeb.ErrorResponse

  def get_me(conn, _params) do
    logged_client = Guardian.Plug.current_resource(conn)

    code =
      case Accounts.get_code(logged_client) do
        {:ok, maybe_code} -> maybe_code
        _ -> nil
      end

    logged_client = Map.put(logged_client, :code, code)

    render(conn, "client_with_code.json", data: logged_client)
  end

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
         {:error, :credential_not_found} <- Accounts.get_credential_by_email(email),
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

      {:ok, _credential} ->
        ErrorResponse.bad_request(conn, "email already in use")

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
        if client.status_complete do
          conn
          |> put_status(201)
          |> render("complete_client.json", data: client)
        else
          conn
          |> put_status(201)
          |> render("client.json", data: client)
        end

      {:error, changeset} ->
        ErrorResponse.bad_request(conn, changeset)
    end
  end

  defp update(conn, client, params) do
    logged_client = Guardian.Plug.current_resource(conn)

    cond do
      is_nil(logged_client) ->
        ErrorResponse.unauthorized(conn)

      logged_client.id != client.id ->
        ErrorResponse.bad_request(conn, "invalid CPF")

      true ->
        case Accounts.update_client(client, params) do
          {:ok, updated_client} ->
            if client.status_complete != updated_client.status_complete do
              render(conn, "complete_client.json", data: updated_client)
            else
              render(conn, "client.json", data: updated_client)
            end

          {:error, :client_not_found} ->
            ErrorResponse.not_found(conn, "client")

          {:error, changeset} ->
            ErrorResponse.bad_request(conn, changeset)
        end
    end
  end

  defp get_referral(code) when is_binary(code) do
    with {:ok, referral} <- Accounts.get_referral(code) do
      {:ok, %{"refered_id" => referral.id}}
    end
  end

  defp get_referral(_code), do: {:ok, %{}}
end
