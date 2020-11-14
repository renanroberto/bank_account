defmodule BankAccountWeb.ErrorResponse do
  @moduledoc "Implements helpers for error responses"

  use BankAccountWeb, :controller

  alias BankAccountWeb.ErrorView

  def bad_request(conn, %Ecto.Changeset{} = changeset) do
    errors =
      Ecto.Changeset.traverse_errors(
        changeset,
        &BankAccountWeb.ErrorHelpers.translate_error/1
      )

    bad_request(conn, errors)
  end

  def bad_request(conn, errors) do
    conn
    |> put_status(400)
    |> put_view(ErrorView)
    |> render("error.json", data: errors)
  end

  def not_found(conn, entity) do
    conn
    |> put_status(404)
    |> put_view(ErrorView)
    |> render("error.json", data: "#{entity} not found")
  end

  def unauthorized(conn) do
    conn
    |> put_status(401)
    |> put_view(ErrorView)
    |> render("error.json", data: "authentication is required")
  end

  def internal_error(conn) do
    conn
    |> put_status(500)
    |> put_view(ErrorView)
    |> render("error.json", data: "internal server error")
  end
end
