defmodule Crit.Repo.Migrations.CreateAudit do
  use Ecto.Migration

  def change do
    create table(:audit_log) do
      add :event_owner_id,
        # User records are never supposed to be deleted.
        references(:users, on_delete: :restrict),
        null: false
      add :event, :string, null: false
      add :version, :integer, null: false, default: 1
      add :data, :map, default: %{}

      timestamps(updated_at: false)
    end

    create index(:audit_log, :event)
  end
end
