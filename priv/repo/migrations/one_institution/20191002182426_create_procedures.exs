defmodule Crit.Repo.Migrations.CreateProcedures do
  use Ecto.Migration

  def change do
    create table(:procedures) do
      add :name, :citext, null: false

      timestamps()
    end

    create unique_index(:procedures, [:name])
  end
end
