defmodule BankAccount.Accounts.Client do
  @moduledoc "Provide the client schema"

  use Ecto.Schema
  import Ecto.Changeset

  schema "clients" do
    field :active, :boolean, default: false
    field :birth_date, :date
    field :city, :string
    field :country, :string
    field :cpf, :string
    field :gender, :string
    field :name, :string
    field :referral_code, :string
    field :state, :string
    field :status_complete, :boolean, default: false
    field :refered, :id

    has_one :credential, BankAccount.Accounts.Credential

    timestamps()
  end

  @doc false
  def changeset(client, attrs) do
    client
    |> cast(attrs, [
      :name,
      :cpf,
      :birth_date,
      :gender,
      :city,
      :state,
      :country,
      :status_complete,
      :referral_code,
      :active
    ])
    |> validate_required([
      :cpf
    ])
    |> unique_constraint(:cpf)
    |> unique_constraint(:referral_code)
  end
end
