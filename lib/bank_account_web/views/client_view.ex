defmodule BankAccountWeb.ClientView do
  use BankAccountWeb, :view

  def render("client.json", %{data: client}) do
    client_json = %{
      id: client.id,
      name: client.name,
      cpf: client.cpf,
      email: client |> Map.get(:credential, %{}) |> Map.get(:email),
      birth_date: client.birth_date,
      city: client.city,
      state: client.state,
      country: client.country,
      gender: client.gender,
      status_complete: client.status_complete
    }

    status = if client.status_complete, do: "complete", else: "pending"

    %{
      status: status,
      client: client_json
    }
  end

  def render("client_with_code.json", %{data: client}) do
    client_json = %{
      id: client.id,
      name: client.name,
      cpf: client.cpf,
      email: client |> Map.get(:credential, %{}) |> Map.get(:email),
      code: client.code,
      birth_date: client.birth_date,
      city: client.city,
      state: client.state,
      country: client.country,
      gender: client.gender,
      status_complete: client.status_complete
    }

    status = if client.status_complete, do: "complete", else: "pending"

    %{
      status: status,
      client: client_json
    }
  end

  def render("complete_client.json", %{data: client}) do
    client_json = %{
      id: client.id,
      name: client.name,
      cpf: client.cpf,
      email: client |> Map.get(:credential, %{}) |> Map.get(:email),
      birth_date: client.birth_date,
      city: client.city,
      state: client.state,
      country: client.country,
      gender: client.gender,
      status_complete: client.status_complete
    }

    %{
      status: "newly_completed",
      message: "congratulations! You've completed your registration",
      code: client.code,
      client: client_json
    }
  end
end
