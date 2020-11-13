defmodule BankAccount.Repo.Migrations.AddReferedFieldOnClients do
  use Ecto.Migration

  def change do
    alter table(:clients) do
      add :refered_id, references(:referrals, on_delete: :nothing)
    end

    create index(:clients, [:refered_id])
  end
end
