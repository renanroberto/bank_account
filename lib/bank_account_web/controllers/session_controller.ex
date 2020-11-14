defmodule BankAccountWeb.SessionController do
  use BankAccountWeb, :controller

  alias BankAccount.Accounts
  alias BankAccount.Accounts.Guardian

  defp fetch_param(params, key) do
    case Map.fetch(params, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, key}
    end
  end

  def login(conn, params) do
    with {:ok, email} <- fetch_param(params, "email"),
         {:ok, password} <- fetch_param(params, "password"),
         {:ok, credential} <- Accounts.authenticate_credential(email, password) do
      conn = Guardian.Plug.sign_in(conn, credential)
      token = Guardian.Plug.current_token(conn)

      json(conn, %{token: token})
    else
      {:error, "email"} ->
        json(conn, %{error: "email is required"})

      {:error, "password"} ->
        json(conn, %{error: "password is required"})

      {:error, :invalid_credentials} ->
        json(conn, %{error: "login or password are incorrect"})

      _ ->
        json(conn, %{error: "something went wrong"})
    end
  end
end
