defmodule BankAccount.Accounts.Client do
  @moduledoc "Provide the client schema"

  use Ecto.Schema
  import Ecto.Changeset

  schema "clients" do
    field :active, :boolean, default: true
    field :birth_date, BankAccount.Encrypted.Date
    field :city, :string
    field :country, :string
    field :cpf, BankAccount.Encrypted.Binary
    field :cpf_hash, Cloak.Ecto.SHA256
    field :gender, :string
    field :name, BankAccount.Encrypted.Binary
    field :name_hash, Cloak.Ecto.SHA256
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
      :refered,
      :referral_code,
      :active
    ])
    |> validate_required([
      :cpf
    ])
    |> unique_constraint(:cpf)
    |> unique_constraint(:referral_code)
    |> put_hashed_fields()
  end

  defp put_hashed_fields(changeset) do
    changeset
    |> put_change(:name_hash, get_field(changeset, :name))
    |> put_change(:cpf_hash, get_field(changeset, :cpf))
  end
end
