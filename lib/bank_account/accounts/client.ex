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
    field :state, :string
    field :status_complete, :boolean, default: false
    field :refered_id, :id

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
      :active,
      :refered_id
    ])
    |> validate_required([
      :cpf
    ])
    |> validate_change(:cpf, &validate_cpf/2)
    |> format_cpf()
    |> put_hashed_fields()
    |> unique_constraint(:cpf)
    |> unique_constraint(:cpf_hash)
  end

  defp validate_cpf(:cpf, cpf) do
    if CPF.valid?(cpf) do
      []
    else
      [cpf: "is invalid"]
    end
  end

  defp format_cpf(%Ecto.Changeset{valid?: true} = changeset) do
    cpf =
      changeset
      |> get_field(:cpf)
      |> CPF.parse!()
      |> to_string()

    changeset
    |> put_change(:cpf, cpf)
  end

  defp format_cpf(changeset), do: changeset

  defp put_hashed_fields(changeset) do
    changeset
    |> put_change(:name_hash, get_field(changeset, :name))
    |> put_change(:cpf_hash, get_field(changeset, :cpf))
  end
end
