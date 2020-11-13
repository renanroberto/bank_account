defmodule BankAccount.Accounts.Referral do
  @moduledoc "Provide the referral schema"

  use Ecto.Schema
  import Ecto.Changeset

  schema "referrals" do
    field :code, :integer
    field :client_id, :id

    timestamps()
  end

  @doc false
  def changeset(referral, attrs) do
    referral
    |> cast(attrs, [:code, :client_id])
    |> validate_required([:code, :client_id])
    |> unique_constraint(:code)
    |> unique_constraint(:client_id)
  end
end
