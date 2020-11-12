defmodule BankAccount.Accounts.Credential do
  @moduledoc "Provides the credential schema"

  use Ecto.Schema
  import Ecto.Changeset

  schema "credentials" do
    field :email, BankAccount.Encrypted.Binary
    field :email_hash, Cloak.Ecto.SHA256
    field :password, :string

    belongs_to :client, BankAccount.Accounts.Client

    timestamps()
  end

  @doc false
  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> unique_constraint(:email)
    |> put_password_hash()
    |> put_hashed_fields()
  end

  defp put_password_hash(
         %Ecto.Changeset{
           valid?: true,
           changes: %{password: password}
         } = changeset
       ) do
    change(changeset, password: Argon2.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset

  defp put_hashed_fields(changeset) do
    changeset
    |> put_change(:email_hash, get_field(changeset, :email))
  end
end
