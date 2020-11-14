defmodule BankAccountWeb.ClientController do
  use BankAccountWeb, :controller

  alias BankAccount.Accounts

  def upsert(conn, params) do
    params =
      Map.drop(params, [
        "active",
        "status_complete",
        "credential",
        "refered_id"
      ])

    email = params["email"]
    password = params["password"]
    credential = %{email: email, password: password}

    cpf = params["cpf"]

    cond do
      is_nil(cpf) ->
        json(conn, %{error: "CPF is required"})

      not CPF.valid?(cpf) ->
        json(conn, %{error: "invalid CPF"})

      true ->
        case Accounts.get_client_by_cpf(params["cpf"]) do
          {:ok, client} ->
            update(conn, client, params)

          {:error, :client_not_found} ->
            create(conn, Map.put(params, "credential", credential))
        end
    end
  end

  defp create(conn, params) do
    case Accounts.create_client(params) do
      {:ok, client} ->
        conn
        |> put_status(201)
        |> json(%{id: client.id, name: client.name})

      {:error, changeset} ->
        IO.inspect(changeset)
        json(conn, %{error: "something went wrong"})
    end
  end

  defp update(conn, client, params) do
    case Accounts.update_client(client, params) do
      {:ok, updated_client} ->
        conn
        |> json(%{id: updated_client.id, name: updated_client.name})

      {:error, :client_not_found} ->
        json(conn, %{error: "client not found"})

      {:error, changeset} ->
        IO.inspect(changeset)
        json(conn, %{error: "something went wrong"})
    end
  end
end
