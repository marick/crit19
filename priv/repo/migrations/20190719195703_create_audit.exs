defmodule Crit.Repo.Migrations.CreateAudit do
  use Ecto.Migration

  def change do
    create table(:audit_log) do
      add :user_responsible, :id, null: false
      add :event, :string, null: false
      add :version, :integer, null: false, default: 1
      add :data, :map, default: %{}

      timestamps(updated_at: false)
    end

    create index(:audit_log, :event)
  end
end
