defmodule BankAccount.Repo.Migrations.CreateClients do
  use Ecto.Migration

  def change do
    create table(:clients) do
      add :name, :binary
      add :name_hash, :binary
      add :cpf, :binary, null: false
      add :cpf_hash, :binary
      add :birth_date, :binary
      add :birth_date_hash, :binary
      add :gender, :string
      add :city, :string
      add :state, :string
      add :country, :string
      add :status_complete, :boolean, default: false, null: false
      add :active, :boolean, default: true, null: false

      timestamps()
    end

    create unique_index(:clients, [:cpf])
  end
end
