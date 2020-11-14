defmodule BankAccountWeb.ClientView do
  use BankAccountWeb, :view

  def render("client.json", %{data: client}) do
    %{
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
  end
end
