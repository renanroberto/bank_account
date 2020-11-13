defmodule BankAccount.Repo.Migrations.CreateReferrals do
  use Ecto.Migration

  def change do
    create table(:referrals) do
      add :code, :integer, null: false
      add :client_id, references(:clients, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:referrals, [:code])
    create unique_index(:referrals, [:client_id])
  end
end
