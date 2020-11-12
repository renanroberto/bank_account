defmodule BankAccount.Repo.Migrations.CreateCredentials do
  use Ecto.Migration

  def change do
    create table(:credentials) do
      add :email, :string, null: false
      add :password, :string, null: false
      add :client_id, references(:clients, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:credentials, [:email])
    create index(:credentials, [:client_id])
  end
end
