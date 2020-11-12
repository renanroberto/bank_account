defmodule BankAccountWeb.ErrorHandlerController do
  use BankAccountWeb, :controller

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    body = %{error: to_string(type)}

    conn
    |> put_status(401)
    |> json(body)
  end
end
