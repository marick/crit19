defmodule Crit.Repo.Migrations.CreateProcedures do
  use Ecto.Migration

  def change do
    create table(:procedures) do
      add :name, :citext, null: false
      # Species cannot be deleted, for the sake of consistency.
      add :species_id, references("species", on_delete: :restrict), null: false

      timestamps()
    end

    create unique_index(:procedures, [:name, :species_id],
      name: :unique_to_species)
  end
end
